//
//  InstantPudding.m
//  SkunkSample
//
//  Created by Jason liang on 14-8-30.
//  Copyright (c) 2014年 Jason liang. All rights reserved.
//

#import "InstantPudding.h"

@implementation InstantPudding

-(id) init
{
	if (self = [super init]) {

    }
	
	return self;
}

- (void)dealloc
{
//    [super dealloc];
}

- (void)UIDCancel
{
	if(UID) {
		IP_UUTCancel(UID);
		UID = NULL;
	}
}


- (BOOL)handleIPReply:(IP_API_Reply)reply
{
	BOOL bOK = false;
	
	if (!IP_success(reply)) {
        NSLog (@"pdca error:%s", IP_reply_getError(reply));
		// this should display an error to the operator, and prevent the unit from passing the test station
	}
	else {
        bOK = true;
    }
	
	IP_reply_destroy(reply);
    reply = NULL;
	
	return bOK;
}

- (BOOL)IPStart
{
    NSLog(@"ipstart");
    BOOL fRet = NO;
    IP_API_Reply reply = NULL;
    
    failedAtLeastOneTest = NO;
    
    reply = IP_UUTStart(&UID);
    
    if ([self handleIPReply:reply])
        fRet = YES;
    else
        [self UIDCancel];
    
    return fRet;
}

- (BOOL)IPamIOkay:(NSString*)sn
{
    BOOL fRet = NO;
    IP_API_Reply reply = NULL;
    
    reply = IP_amIOkay(UID, [sn UTF8String]);
    
    if ([self handleIPReply:reply])
        fRet = YES;
    else
        [self UIDCancel];
    
    return fRet;
}

-(IP_API_Reply)IPamIOkayRelay:(NSString*)sn
{
    IP_API_Reply reply = NULL;
    reply = IP_amIOkay(UID, [sn UTF8String]);
    return reply;
}

-(NSString *)GetIPVersion{
    const char *version=IP_getVersion();
    return [NSString stringWithUTF8String:version];
}

- (BOOL)IPDoneAndCommitWithResult:(BOOL )result
{
    BOOL bOK = YES;
    if ([self handleIPReply:IP_UUTDone(UID)])
    {
//        [self handleIPReply:IP_UUTDone(UID)];
        NSLog(@"IP_UUTDone Success");
        if ([self handleIPReply:IP_UUTCommit(UID, result ? IP_FAIL : IP_PASS)]) {
            NSLog(@"IPDoneAndCommit Success");
            IP_UID_destroy(UID);
        } else {
            NSLog(@"IPDoneAndCommit Fail");
            [self UIDCancel];
            bOK = NO;
        }
    }
    else {
        NSLog(@"IP_UUTDone Fail");
        [self UIDCancel];
        bOK = NO;
    }
    return bOK;
}

-(void)IPDoneWithResult:(BOOL) result{
    IP_reply_destroy(IP_UUTDone(UID));
    
    IP_reply_destroy(IP_UUTCommit(UID, result ? IP_PASS:IP_FAIL));
    
    IP_UID_destroy(UID);
}
-(BOOL)addBlobFile:(NSString *)SWName logFileName:(NSString *)fileName{
    BOOL fRet = NO;
    IP_API_Reply reply = NULL;
    
    NSString *tt=[SWName stringByAppendingString: @"_log"];
    reply = IP_addBlob(UID,[tt cStringUsingEncoding:1],[fileName cStringUsingEncoding:1]);
    
    if ([self handleIPReply:reply])
        fRet = YES;
    else
        [self UIDCancel];
    
    return fRet;
    
}
- (void)GetIPStationType:(NSString **)strRet
{
    IP_API_Reply reply = NULL;
	size_t length;
	char* stationType;
    
	IP_getGHStationInfo(UID, IP_STATION_TYPE, NULL, &length);
	
	stationType = malloc(length + 1);
	
	reply = IP_getGHStationInfo(UID, IP_STATION_TYPE, &stationType, &length);
	
    if ([self handleIPReply:reply]) {
//        NSMutableString* result = [[NSMutableString alloc] initWithString:@""];
//        [result appendFormat:@"%s", stationType];
        *strRet = [NSString stringWithFormat:@"%s", stationType];
    }
    
    free(stationType);
}

- (BOOL)ValidateSerialNumber:(NSString*)sn
{
    BOOL fRet = NO;
    IP_API_Reply reply = NULL;
    
	reply = IP_validateSerialNumber(UID, [sn UTF8String]);
	
	if ([self handleIPReply:reply])
        fRet = YES;
    else
        [self UIDCancel];
	
	return fRet;
}

- (BOOL)AddIPAttribute:(NSString*)name Value:(NSString*)value
{
    BOOL fRet = NO;
    IP_API_Reply reply = NULL;
    
	reply = IP_addAttribute(UID, [name UTF8String], [value UTF8String]);
	
    if ([self handleIPReply:reply])
        fRet = YES;
    else
        [self UIDCancel];
	
	return fRet;
}

- (BOOL)AddIPTestItem:(NSString*)itemName TestValue:(NSString*)testValue
           LowerLimit:(NSString*)lowerLimit UpperLimit:(NSString*)upperLimit
             Priority:(enum IP_PDCA_PRIORITY)priority Units:(NSString*)units
{
    BOOL fRet = NO;
    IP_API_Reply reply = NULL;
    IP_TestSpecHandle	testSpec = NULL;
	IP_TestResultHandle testResult = NULL;
    NSString *strErrorInfo = nil;
    
    // create a test spec from the struct contents
    testSpec = IP_testSpec_create();
    
    if (!testSpec) {
        NSLog (@"Error from IP_testSpec_create %@",itemName);
		[self UIDCancel];
        goto Finish;
    }
    
    testResult = IP_testResult_create();
    
    if (!testResult) {
        NSLog(@"Error from IP_testResult_create %@",itemName);
		[self UIDCancel];
        goto Finish;
    }
    
    IP_testSpec_setTestName(testSpec, [itemName UTF8String], [itemName length]);
    IP_testSpec_setPriority(testSpec, priority);
    IP_testSpec_setLimits(testSpec, [lowerLimit UTF8String], [lowerLimit length],
                          [upperLimit UTF8String], [upperLimit length]);
    IP_testSpec_setUnits(testSpec, [units UTF8String], [units length]);
    IP_testResult_setValue(testResult, [testValue UTF8String], [testValue length]);
    
    //compare test result isPass
    NSInteger iResult = [self compareValue:testValue withMax:upperLimit andMin:lowerLimit];
    
    switch (iResult) {
        case 0:
            failedAtLeastOneTest = YES;
            strErrorInfo = @"FAIL";
            IP_testResult_setResult(testResult, IP_FAIL);
            break;
        case 1:
            strErrorInfo = @"PASS";
            IP_testResult_setResult(testResult, IP_PASS);
            break;
        case 2:
            strErrorInfo = @"PASS";
            IP_testResult_setResult(testResult, IP_NA);
            break;
            
        default:
            break;
    }
    
    IP_testResult_setMessage(testResult, [strErrorInfo UTF8String], [strErrorInfo length]);
    
    reply = IP_addResult(UID, testSpec, testResult);
    
    if ([self handleIPReply:reply])
        fRet = YES;
    else
        [self UIDCancel];

Finish:
	if (testResult)
		IP_testResult_destroy(testResult);
	if (testSpec)
		IP_testSpec_destroy(testSpec);
    
    return fRet;
}

- (NSInteger)compareValue:(NSString*)value withMax:(NSString *)max andMin:(NSString *)min
{
    NSInteger iRet = 0;
    
    if (([min isEqualToString:@"NA"] || [min isEqualToString:@""])
        && !([max isEqualToString:@"NA"] || [max isEqualToString:@""])) {
        if ([value floatValue] < [max floatValue]) {
            iRet = 1;
        }
    }
    else if (!([min isEqualToString:@"NA"] || [min isEqualToString:@""])
             && ([max isEqualToString:@"NA"] || [max isEqualToString:@""])){
        if ([value floatValue] >= [min floatValue]) {
            iRet = 1;
        }
    }
    else if (([min isEqualToString:@"NA"] || [min isEqualToString:@""])
              && ([max isEqualToString:@"NA"] || [max isEqualToString:@""])){
        iRet = 2;
    }
    else{
        if ([value floatValue] >= [min floatValue] && [value floatValue] <= [max floatValue]) {
            iRet = 1;
        }
    }
    return iRet;
}

- (BOOL)SetStartTime:(time_t)startTime
{
    BOOL fRet = NO;
    IP_API_Reply reply = NULL;
    
	reply = IP_setStartTime(UID, startTime);
	
    if ([self handleIPReply:reply])
        fRet = YES;
    else
        [self UIDCancel];
	
	return fRet;
}

- (BOOL)SetStopTime:(time_t)stopTime
{
    BOOL fRet = NO;
    IP_API_Reply reply = NULL;
    
	reply = IP_setStopTime(UID, stopTime);
	
    if ([self handleIPReply:reply])
        fRet = YES;
    else
        [self UIDCancel];
	
	return fRet;
}

@end
