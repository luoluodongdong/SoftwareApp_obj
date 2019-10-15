//
//  InstantPudding.h
//  SkunkSample
//
//  Created by Jason liang on 14-8-30.
//  Copyright (c) 2014年 Jason liang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "InstantPudding_API.h"

@interface InstantPudding : NSObject
{
    IP_UUTHandle UID;
    BOOL failedAtLeastOneTest;
}
-(NSString *)GetIPVersion;
- (BOOL)IPStart;
- (BOOL)IPamIOkay:(NSString*)sn;
- (void)GetIPStationType:(NSString **)strRet;
- (BOOL)ValidateSerialNumber:(NSString*)sn;
- (BOOL)AddIPAttribute:(NSString*)name Value:(NSString*)value;
- (BOOL)AddIPTestItem:(NSString*)itemName TestValue:(NSString*)testValue
           LowerLimit:(NSString*)lowerLimit UpperLimit:(NSString*)upperLimit
             Priority:(enum IP_PDCA_PRIORITY)priority Units:(NSString*)units;
- (BOOL)IPDoneAndCommitWithResult:(BOOL )result;
-(void)IPDoneWithResult:(BOOL) result;
-(BOOL)addBlobFile:(NSString *)SWName logFileName:(NSString *)fileName;
- (BOOL)SetStartTime:(time_t)startTime;
- (BOOL)SetStopTime:(time_t)stopTime;
-(IP_API_Reply)IPamIOkayRelay:(NSString*)sn;

@end
