//
//  AppDelegate.m
//  SoftwareApp
//
//  Created by 曹伟东 on 2019/3/29.
//  Copyright © 2019年 曹伟东. All rights reserved.
//

#import "AppDelegate.h"

#define TV_COLUMN_COUNT     9 //TableView column count
/*Table Data Item Index*/
#define TV_ITEM_INDEX       0 //TableView test item name
#define TV_STATUS_INDEX     1
#define TV_VALUE_INDEX      2
#define TV_LOW_INDEX        3
#define TV_REFERENCE_INDEX  4
#define TV_UP_INDEX         5
#define TV_UNIT_INDEX       6
#define TV_DURATION_INDEX   7

#define TP_COLUMN_COUNT     15
/*Test Plan Item Index*/
#define TP_TESTITEMS_INDEX  0
#define TP_GROUP_INDEX      1
#define TP_FUNC_INDEX       2
#define TP_CMD_INDEX        3
#define TP_RECSUF_INDEX     4
#define TP_VALTYP_INDEX     5
#define TP_VALSAV_INDEX     6
#define TP_LOW_INDEX        7
#define TP_REFERENCE_INDEX  8
#define TP_UP_INDEX         9
#define TP_UNIT_INDEX       10
#define TP_TIMEOUT_INDEX    11
#define TP_DELAY_INDEX      12
#define TP_EXITENABLE_INDEX 13
#define TP_SKIP_INDEX       14

@interface AppDelegate ()
{
    //tableview datasource
    NSMutableArray *_tableData[TV_COLUMN_COUNT-1];
    //testplan data
    NSMutableArray *_testPlanData[TP_COLUMN_COUNT];
    
}

@property (nonatomic,strong) NSThread *mainThread;
@property (nonatomic,assign) int rowRefresh;
//Yield Panel
@property (nonatomic,assign) int inputCount;
@property (nonatomic,assign) int passCount;
@property (nonatomic,assign) int failCount;
@property (nonatomic,strong) NSString *testConfigFile;
@property (nonatomic,strong) NSString *testplanFile;
//Root Set Dictionary
@property (nonatomic,strong) NSDictionary *rootSet;
//Test Set Dictionary
@property (nonatomic,strong) NSDictionary *testSet;
@property (nonatomic,strong) NSString *swName;
@property (nonatomic,strong) NSString *swVersion;
@property (atomic,assign) BOOL TESTING_FLAG;
@property (nonatomic,strong) NSString *testResult;
@property (nonatomic,strong) NSString *snString;
@property (nonatomic,strong) NSString *testMode;
@property (nonatomic,strong) NSString *logString;
@property (nonatomic,strong) NSLock *lock;
@property (nonatomic,strong) NSString *errMsg;
@property (nonatomic,assign) BOOL devOpenIsOK;
@property (nonatomic,assign) BOOL setViewLocked;
@property (nonatomic,strong) NSString *recString;
@property (nonatomic,strong) welcomeView *welcomePage;
@property (nonatomic,strong) myConfigView *configView;
@property (nonatomic,strong) ExitView *exitView;
@property (nonatomic,strong) myPassWord *passwordVC;

@property (nonatomic,strong) NSMutableArray *startScriptArr;

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    /*-----------------------Welcome View------------------------------*/
    _welcomePage=[[welcomeView alloc] initWithWindowNibName:@"welcomeWin"];
    _welcomePage.delegate=self;
    _welcomePage.autoLogin=YES;
    _welcomePage.userName=@"TE";
    _welcomePage.passWord=@"123";
    [_welcomePage showWindow:_welcomePage.window];
    /*-----------------------End Welcome View--------------------------*/
    NSLog(@"launch done.");

//    MEShelper *mesHelper=[[MEShelper alloc] init];
//    NSString *theValue=[mesHelper GetGHDValueWithKey:@"STATION_ID"];
//    NSLog(@"theValue:%@",theValue);
//    //BOOL snIsOK=[mesHelper checkUOPwithBody:@"c=QUERY_RECORD&sn={SN}&StationID={STID}&cmd=QUERY_PANEL" sn:@"YM123456789"];
//    //NSLog(@"snIsOK；%hhd",snIsOK);
//    NSString *url=@"http://10.37.66.2:8005/LuxShare_QualityTestService.aspx";
//    NSString *body=@"c=QUERY_RECORD&sn=DLC8522000CKQV6A2&StationID=ITKS_E04-3FAP-03_1_Lisa-FCT";
//    NSString *response=[mesHelper POSTwithURL:url Body:body];
//    NSLog(@"the response:%@",response);
    

    
}
-(id)init{
    _testConfigFile=@"StationCfg.plist";
    //_mainVC=[[NSViewController alloc]init];
    //_mainVC=self.window.contentViewController;
    NSString *rawfilePath=[[NSBundle mainBundle] resourcePath];
    NSString *filePath;
    filePath=[rawfilePath stringByAppendingPathComponent:_testConfigFile];
    _rootSet=[[NSDictionary alloc] initWithContentsOfFile:filePath];
    _testSet=[_rootSet objectForKey:@"cfg"];
    _swName=[_testSet objectForKey:@"SWname"];
    _swVersion=[_testSet objectForKey:@"SWversion"];
    _testplanFile=[_testSet objectForKey:@"TestPlanFile"];
    _testSet=[_rootSet objectForKey:@"yield"];
    _inputCount = [[_testSet objectForKey:@"Input"] intValue];
    _passCount=[[_testSet objectForKey:@"Pass"] intValue];
    _failCount=_inputCount-_passCount;
    
    _testSet=[_rootSet objectForKey:@"startScripts"];
    _startScriptArr=[[NSMutableArray alloc] initWithCapacity:1];
    for (int i=0; i<[[_testSet allKeys] count]; i++) {
        NSString *key=[NSString stringWithFormat:@"%d",i];
        [_startScriptArr addObject:[_testSet objectForKey:key]];
    }
    NSLog(@"_startScriptArr:%@",_startScriptArr);
    
    _rowRefresh = 0;
    for (int i=0; i<TV_COLUMN_COUNT-1; i++) {
        _tableData[i] =[[NSMutableArray alloc] initWithCapacity:1];
    }
    
    for (int i=0; i<TP_COLUMN_COUNT; i++) {
        _testPlanData[i]=[[NSMutableArray alloc] initWithCapacity:1];
    }
    
    [self loadTestPlan];
    return self;
}


/*1.*/
-(void)initUI{
    _lock=[[NSLock alloc] init];
    _logString=@"----LOG-----\n";
    _testResult=@"READY";
    //test mode
    _testMode=@"Normal";
    [_modeBtn removeAllItems];
    [_modeBtn addItemsWithTitles:@[@"Normal",@"Audit"]];
    [_modeBtn selectItemAtIndex:0];
    [_auditLabel setHidden:YES];
    
    _TESTING_FLAG=NO;
    _setViewLocked=YES;
    [_swNameTF setStringValue:_swName];
    [_verTF setStringValue:_swVersion];
    [self updateYield:NO];
    [_snTF setStringValue:@""];
    [_snTF becomeFirstResponder];
    _devOpenIsOK=YES;
}
/*2.*/
-(void)executeScriptsFunc{
    for (NSString *cmd in _startScriptArr) {
        NSString *result=[self cmdExe:cmd];
        [self logUpdate:result];
    }
    
    NSString *rawfilePath=[[NSBundle mainBundle] resourcePath];
    NSString *cmd=[rawfilePath stringByAppendingPathComponent:@"/ExtendScripts/myPyServer.py"];
    cmd=[@"/Users/weidongcao/anaconda3/bin/python " stringByAppendingString:cmd];
    [self logUpdate:cmd];
    //const char *cmdC=[cmd UTF8String];
    //system(cmdC);
    [self syncEcecutePythonCmd:cmd];
}
/*3.*/
-(void)loadDevices{
    _devOpenIsOK = NO;
    //*************Config View**************************//
    _configView=[[myConfigView alloc] initWithNibName:@"ConfigView" bundle:nil];
    _configView.dictKey=@"Devices";
    _configView.delegate=self;
    
    [_configView initView];
    //*****************End Config View******************//
}

/*6.*/
-(void)loadUIstaus{
    
    if (!_devOpenIsOK) {
        [_statusTF setStringValue:@"ERROR"];
        [_statusTF setBackgroundColor:[NSColor systemRedColor]];
    }
    
}

-(void)loadProgressThread{
    
    /*1.*/
    [_welcomePage updateStatus:@"init UI..." progress:20.0];
    [self performSelectorOnMainThread:@selector(initUI) withObject:nil waitUntilDone:YES];
    [NSThread sleepForTimeInterval:0.5];
    /*2.*/
    [_welcomePage updateStatus:@"execute extend scripts..." progress:40.0];
    [self executeScriptsFunc];
    [NSThread sleepForTimeInterval:2.0];
    /*3.*/
    [_welcomePage updateStatus:@"load serial panel..." progress:80.0];
    [self performSelectorOnMainThread:@selector(loadDevices) withObject:nil waitUntilDone:YES];
    [NSThread sleepForTimeInterval:0.5];
    
    /*6.*/
    [_welcomePage updateStatus:@"load UI status..." progress:100.0];
    [self performSelectorOnMainThread:@selector(loadUIstaus) withObject:nil waitUntilDone:YES];
    [NSThread sleepForTimeInterval:0.5];
    [_welcomePage closePage];
    dispatch_async(dispatch_get_main_queue(), ^{
        //通知主线程更新
        [self->_window setIsVisible:YES];
    });
    NSLog(@"load progress finish");
}
#pragma welcome view delegate event
-(void)msgFromWelcomeView:(NSString *)msg{
    NSLog(@"welcome page msg:%@",msg);
    if ([msg isEqualToString:@"cancel"]) {
        //[[self.window standardWindowButton:NSWindowCloseButton] performClick:self];
        [NSApp terminate:self];
        return;
    }

    if([msg isEqualToString:@"login"]){
        [self performSelectorInBackground:@selector(loadProgressThread) withObject:nil];
    }
    
}
-(IBAction)devCfgBtnAction:(id)sender{
    [_mainVC presentViewControllerAsModalWindow:_configView];
    [self logUpdate:@"present ConfigView..."];
}

-(void)loadTestPlan{
    NSString *rawfilePath=[[NSBundle mainBundle] resourcePath];
    NSString *fileSuffix=[NSString stringWithFormat:@"/%@",_testplanFile];
    NSString *filePath=[rawfilePath stringByAppendingPathComponent:fileSuffix];
    
    CSVParser *parser=[CSVParser new];
    [parser openFile:filePath];
    NSMutableArray *csvContent = [parser parseFile];
    //NSLog(@"%@", csvContent);
    [parser closeFile];
    //NSMutableArray *heading = [csvContent objectAtIndex:0];
    [csvContent removeObjectAtIndex:0];
    
    //NSArray *line=[csvContent objectAtIndex:0];
    //NSLog(@"%@", line);
    for (int i=0; i<TV_COLUMN_COUNT-1; i++) {
        [_tableData[i] removeAllObjects];
    }
    
    for (int i=0; i<TP_COLUMN_COUNT; i++) {
        [_testPlanData[i] removeAllObjects];
    }
    
    for (int index=0; index<[csvContent count]; index++) {
        NSArray *line=[csvContent objectAtIndex:index];
        for (int i=0; i<TP_COLUMN_COUNT; i++) {
            [_testPlanData[i] addObject:line[i]];
        }
        
    }
    _tableData[TV_ITEM_INDEX] = _testPlanData[TP_TESTITEMS_INDEX];
    _tableData[TV_LOW_INDEX] = _testPlanData[TP_LOW_INDEX];
    _tableData[TV_REFERENCE_INDEX] = _testPlanData[TP_REFERENCE_INDEX];
    _tableData[TV_UP_INDEX] = _testPlanData[TP_UP_INDEX];
    _tableData[TV_UNIT_INDEX] = _testPlanData[TP_UNIT_INDEX];
    //NSLog(@"%@",_unitsData);
}
-(IBAction)goHomeBtnAction:(id)sender{
    [_mainTabView selectTabViewItemAtIndex:0];
    _setViewLocked = YES;
}
-(IBAction)goLogBtnAction:(id)sender{
    [_mainTabView selectTabViewItemAtIndex:1];
    _setViewLocked = YES;
}
-(IBAction)goSetBtnAction:(id)sender{
    if (!_setViewLocked) {
        return;
    }
    _testSet=[_rootSet objectForKey:@"cfg"];
    //init myPassWord ViewController
    _passwordVC=[[myPassWord alloc]initWithNibName:@"myPassWord" bundle:nil];
    _passwordVC.delegate=self; //protocol delegate init **
    _passwordVC._passwordStr=[_testSet objectForKey:@"PassWord"];
    [_mainVC presentViewControllerAsSheet:_passwordVC];
    
}
-(IBAction)modeBtnAction:(id)sender{
    _testMode=[[_modeBtn selectedItem] title];
    NSLog(@"Change test mode:%@",_testMode);
    if ([_testMode isEqualToString:@"Audit"]) {
        [_auditLabel setHidden:NO];
    }else{
        [_auditLabel setHidden:YES];
    }
}
- (void)msgFromPassWord:(BOOL)message {
    NSLog(@"password result:%hhd",message);
    if(message){
        [_mainTabView selectTabViewItemAtIndex:2];
        _setViewLocked=NO;
        return;
    }else{
        _setViewLocked=YES;
        [_mainTabView selectTabViewItemAtIndex:0];
    }
}
-(IBAction)scanSnAction:(id)sender{
    if([self checkInputSn]) [_startBtn performClick:self];
}
-(BOOL)checkInputSn{
    _snString=[_snTF stringValue];
    if ([_snString length] == 0) {
        return NO;
    }
    [self logUpdate:[NSString stringWithFormat:@"SN:%@",_snString]];
    /*
    if(_UPDATE_PDCA){
        BOOL result=[self checkRouterWithSN:_snString];
        if (!result) {
            [self logUpdate:@"SN process error"];
            [_snTF setStringValue:@""];
            [_snTF becomeFirstResponder];
            return NO;
        }
    }
     */
    return YES;
}
-(IBAction)startBtnAction:(id)sender{
    _logString=@"-----LOG-----\n";
    if (!_devOpenIsOK) {
        [self showAlertViewWarning:@"ERROR:devices not ready!"];
        [_statusTF setStringValue:@"ERROR"];
        [_statusTF setBackgroundColor:[NSColor systemRedColor]];
        [_snTF setStringValue:@""];
        return;
    }
//    if(_myInstr34970._instrFD == -1){
//        [self showAlertViewWarning:@"ERROR:Instrument port not opened!"];
//        [_statusTF setStringValue:@"ERROR"];
//        [_statusTF setBackgroundColor:[NSColor systemRedColor]];
//        [_snTF setStringValue:@""];
//        return;
//    }
    if(![self checkInputSn]) return;
    //init tableview
    _rowRefresh =-1;
    [_tableData[TV_STATUS_INDEX] removeAllObjects];
    [_tableData[TV_VALUE_INDEX] removeAllObjects];
    [_tableData[TV_DURATION_INDEX] removeAllObjects];
    [_tableView reloadData];
    [self updateTable];
    //运行主线程
    if(![_mainThread isExecuting]){
        _TESTING_FLAG=YES;
        _mainThread=[[NSThread alloc] initWithTarget:self selector:@selector(threadTest) object:nil];
        [_mainThread start];
        [NSThread detachNewThreadSelector:@selector(testTimeTrack) toTarget:self withObject:nil];
    }
}

-(IBAction)cleanBtnAction:(id)sender{
    _failCount=0;
    _passCount=0;
    [self updateYield:YES];
}

#pragma config view delegate method
- (void)msgFromConfigView:(NSString *)msg {
    NSString *log=[NSString stringWithFormat:@"msg:%@ from config view",msg];
    [self logUpdate:log];
    //DUT connect status:"STATUS:0"
    if ([msg hasPrefix:@"STATUS"]) {
        NSArray *tempArr=[msg componentsSeparatedByString:@":"];
        _devOpenIsOK=[tempArr[1] boolValue];
        if (_devOpenIsOK) {
            [_statusTF setStringValue:@"Ready"];
            [_statusTF setBackgroundColor:[NSColor systemBlueColor]];
        }else{
            [_statusTF setStringValue:@"Error"];
            [_statusTF setBackgroundColor:[NSColor systemBlueColor]];
        }
        
    }
}

- (NSString *)cmdExe:(NSString *)cmd
{
    // 初始化并设置shell路径
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath: @"/bin/bash"];
    // -c 用来执行string-commands（命令字符串），也就说不管后面的字符串里是什么都会被当做shellcode来执行
    NSArray *arguments = [NSArray arrayWithObjects: @"-c", cmd, nil];
    [task setArguments: arguments];
    
    // 新建输出管道作为Task的输出
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput: pipe];
    NSPipe *pipe2=[NSPipe pipe];
    [task setStandardError:pipe2];
    
    // 开始task
    NSFileHandle *file = [pipe fileHandleForReading];
    NSFileHandle *file2 = [pipe2 fileHandleForReading];
    [task launch];
    [task waitUntilExit]; //执行结束后,得到执行的结果字符串++++++
    NSData *data;
    data = [file readDataToEndOfFile];
    NSString *result_str;
    NSString *error_str=[[NSString alloc] initWithData:[file2 readDataToEndOfFile] encoding:NSUTF8StringEncoding];
    if(![error_str isEqualToString:@""]) {
        //error_flag = true;
    }
    NSLog(@"error:%@",error_str);
    result_str = [[NSString alloc] initWithData: data encoding:NSUTF8StringEncoding]; //---------------------------------
    result_str=[result_str stringByAppendingString:error_str];
    return result_str;
}
-(void)syncEcecutePythonCmd:(NSString *)cmd{
    // 初始化并设置shell路径
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath: @"/bin/bash"];
    // -c 用来执行string-commands（命令字符串），也就说不管后面的字符串里是什么都会被当做shellcode来执行
    NSArray *arguments = [NSArray arrayWithObjects: @"-c", cmd, nil];
    [task setArguments: arguments];
    
    [task launch];
}
-(void)threadTest{
    //[self performSelectorOnMainThread:@selector(showPanel:) withObject:@"Connect DUT,OK?" waitUntilDone:YES];
    [self logUpdate:@"====================Main Test Func=========================="];
    _testResult=@"PASS";
    _recString=@"";
    NSString *_save_string_value=@"";
    NSString *_failList=@"";
    int skip_count=0;
    //main test function
    for (int i=0; i<[_testPlanData[TP_TESTITEMS_INDEX] count]; i++) {
        [self logUpdate:@"------------------------------------------------------"];
        NSDate *startT=[NSDate date];
        _rowRefresh++;
        NSString *thisItem=[_testPlanData[TP_TESTITEMS_INDEX] objectAtIndex:i];
        NSString *thisGroup=[_testPlanData[TP_GROUP_INDEX] objectAtIndex:i];
        NSString *thisFunc=[_testPlanData[TP_FUNC_INDEX] objectAtIndex:i];
        NSString *thisCommand=[_testPlanData[TP_CMD_INDEX] objectAtIndex:i];
        //NSString *thisResSuffix=[_testPlanData[TP_RECSUF_INDEX] objectAtIndex:i];
        NSString *thisValueType=[_testPlanData[TP_VALTYP_INDEX] objectAtIndex:i];
        int thisSaveValue=[[_testPlanData[TP_VALSAV_INDEX] objectAtIndex:i] intValue];
        NSString *thisLow=[_testPlanData[TP_LOW_INDEX] objectAtIndex:i];
        NSString *thisReferValue=[_testPlanData[TP_REFERENCE_INDEX] objectAtIndex:i];
        NSString *thisUp=[_testPlanData[TP_UP_INDEX] objectAtIndex:i];
        NSString *thisUnit=[_testPlanData[TP_UNIT_INDEX] objectAtIndex:i];
        double thisTimeOut=[[_testPlanData[TP_TIMEOUT_INDEX] objectAtIndex:i] doubleValue];
        double thisDelay=[[_testPlanData[TP_DELAY_INDEX] objectAtIndex:i] doubleValue];
        int thisExitEnable=[[_testPlanData[TP_EXITENABLE_INDEX] objectAtIndex:i] intValue];
        int thisSkip=[[_testPlanData[TP_SKIP_INDEX] objectAtIndex:i] intValue];
        
        NSString *msg=[NSString stringWithFormat:@"item:%@",thisItem];
        [self logUpdate:msg];
        [_tableData[TV_STATUS_INDEX] addObject:@"Test..."];
        [self performSelectorOnMainThread:@selector(updateTable) withObject:nil waitUntilDone:YES];
        
        NSString *thisValue=@"";
        NSString *thisStatus=@""; //SKIPPED FAIL PASS
        
        if (skip_count > 0) {
            thisValue=@"skip";
            thisStatus=@"SKIPPED"; //SKIPPED FAIL PASS
            skip_count = skip_count - 1;
        }
        else if(thisSkip == 1){
            thisValue=@"skip";
            thisStatus=@"SKIPPED"; //SKIPPED FAIL PASS
        }
        else{
            if ([thisFunc isEqualToString:@"SERIAL"]) {
                msg=[NSString stringWithFormat:@"[TX]%@",thisCommand];
                [self logUpdate:msg];
                thisCommand=[thisCommand stringByAppendingString:@"\r\n"];
                thisValue=[_configView sendCmd:thisCommand TimeOut:thisTimeOut withName:@"DUT"];
                BOOL isTimeOut= [thisValue  isEqual: @""] ? YES : NO;
                //just test instrument panel
                //BOOL isTimeOut=NO;
                //thisValue=[_myInstr34970 queryInstr:thisCommand];
                
                msg=[NSString stringWithFormat:@"[RX]%@",thisValue];
                [self logUpdate:msg];
                if (thisSaveValue == 1) {
                    _save_string_value=thisValue;
                    _save_string_value=[_save_string_value stringByReplacingOccurrencesOfString:@"\r" withString:@""];
                    _save_string_value=[_save_string_value stringByReplacingOccurrencesOfString:@"\n" withString:@""];
                }
                if (isTimeOut) {
                    thisValue=@"timeout";
                    thisStatus=@"FAIL";
                }else{
                    if ([thisValueType isEqualToString:@"string"]) {
                        thisStatus=[thisValue containsString:thisReferValue] ? @"PASS" : @"FAIL";
                    }
                }
                if ([thisStatus isEqualToString:@"FAIL"]) {
                    
                }
                
            }
            else if([thisFunc isEqualToString:@"connectFIX"]){
                msg=[NSString stringWithFormat:@"[TX]%@",thisCommand];
                [self logUpdate:msg];
                thisCommand=[thisCommand stringByAppendingString:@"\r\n"];
                thisValue=[_configView sendCmd:thisCommand TimeOut:thisTimeOut withName:@"DUT"];
                BOOL isTimeOut= [thisValue  isEqual: @""] ? YES : NO;
            
                //just test instrument panel
                //BOOL isTimeOut=NO;
                //thisValue=[_myInstr34970 queryInstr:thisCommand];
                
                msg=[NSString stringWithFormat:@"[RX]%@",thisValue];
                [self logUpdate:msg];
                if (isTimeOut) {
                    thisValue=@"timeout";
                    thisStatus=@"FAIL";
                }else{
                    if ([thisValueType isEqualToString:@"string"]) {
                        thisStatus=[thisValue containsString:thisReferValue] ? @"PASS" : @"FAIL";
                    }else{
                        thisStatus=@"PASS";
                    }
                }
                if (thisSaveValue == 1) {
                    _save_string_value=thisValue;
                    _save_string_value=[_save_string_value stringByReplacingOccurrencesOfString:@"\r" withString:@""];
                    _save_string_value=[_save_string_value stringByReplacingOccurrencesOfString:@"\n" withString:@""];
                }
            }
            else if([thisFunc isEqualToString:@"feedback"]){
                //+9.10000000E+37,+9.20000000E+37,+9.30000000E+37,+9.40000000E+37,+9.50000000E+37
                NSArray *feedbackArr=[_save_string_value componentsSeparatedByString:@","];
                int index=[thisCommand intValue]-1;
                
                if (index<[feedbackArr count]) {
                    thisValue=[feedbackArr objectAtIndex:index];
                    if ([self judgeValue:thisValue low:thisLow up:thisUp]) {
                        thisStatus=@"PASS";
                    }else{
                        thisStatus=@"FAIL";
                    }
                }else{
                    thisValue=@"NA";
                    thisStatus=@"FAIL";
                }
            }
            else if([thisFunc isEqualToString:@"connectREAD"]){
                msg=[NSString stringWithFormat:@"[TX]%@",thisCommand];
                [self logUpdate:msg];
                thisCommand=[thisCommand stringByAppendingString:@"\r\n"];
                thisValue=[_configView sendCmd:thisCommand TimeOut:thisTimeOut withName:@"DUT"];
                BOOL isTimeOut= [thisValue  isEqual: @""] ? YES : NO;
                //just test instrument panel
                //BOOL isTimeOut=NO;
                //thisValue=[_myInstr34970 queryInstr:thisCommand];
                
                msg=[NSString stringWithFormat:@"[RX]%@",thisValue];
                if (isTimeOut) {
                    thisValue=@"timeout";
                    thisStatus=@"FAIL";
                }else{
                    NSArray *tempArr=[thisValue componentsSeparatedByString:@"_"];
                    NSInteger len=0;
                    if ([thisGroup isEqualToString:@"STEP"]) {
                        len=[tempArr[0] length]-1;
                    }else{
                        len=[tempArr[0] length]-2;
                    }
                    NSString *tempValue=[tempArr[0] substringWithRange:NSMakeRange(0, len)];
                    thisValue=tempValue;
                    if ([self judgeValue:thisValue low:thisLow up:thisUp]) {
                        thisStatus=@"PASS";
                    }else{
                        thisStatus=@"FAIL";
                    }
                }
        
            }
            else if([thisFunc isEqualToString:@"socket"]){
                thisValue=[_configView sendCmd:thisCommand TimeOut:thisTimeOut withName:@"PYClient"];
                //BOOL isTimeOut= [thisValue  isEqual: @""] ? YES : NO;
                //thisValue=[_mySocketPanel query:thisCommand];
                thisStatus=[thisValue containsString:thisReferValue] ? @"PASS":@"FAIL";
            }
            else if([thisFunc isEqualToString:@"dialog"]){
                thisCommand=[thisCommand stringByReplacingOccurrencesOfString:@"@" withString:@","];
                [self performSelectorOnMainThread:@selector(showAlertViewWarning:) withObject:thisCommand waitUntilDone:YES];
                thisValue=@"OK";
                thisStatus=@"PASS";
                
            }else{
                thisValue=@"NO FUNC";
                thisStatus=@"FAIL";
            }
            [NSThread sleepForTimeInterval:thisDelay];
        }
        //testing part
        //[NSThread sleepForTimeInterval:0.2];

        thisValue=[thisValue stringByReplacingOccurrencesOfString:@"," withString:@"@"];
        thisValue=[thisValue stringByReplacingOccurrencesOfString:@"\r" withString:@""];
        thisValue=[thisValue stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
        NSDate *endT=[NSDate date];
        NSTimeInterval detla_t=[endT timeIntervalSinceDate:startT];
        NSString *thisDuration=[NSString stringWithFormat:@"%.4fs",detla_t];
        msg=[NSString stringWithFormat:@"value:%@ result:%@ low:%@ up:%@ unit:%@ duration:%.4fs",
             thisValue,thisStatus,thisLow,thisUp,thisUnit,detla_t];
        [self logUpdate:msg];
        [_tableData[TV_STATUS_INDEX] replaceObjectAtIndex:i withObject:thisStatus];
        [_tableData[TV_VALUE_INDEX] addObject:thisValue];
        [_tableData[TV_DURATION_INDEX] addObject:thisDuration];
        [self performSelectorOnMainThread:@selector(updateTable) withObject:nil waitUntilDone:YES];

        if ([thisStatus isEqualToString:@"FAIL"]) {
            
            _failList =[_failList stringByAppendingString:[NSString stringWithFormat:@"@%@",thisItem]];
            _testResult=@"FAIL";
            if (thisExitEnable > 1) {
                skip_count = thisExitEnable-1;
            }else if(thisExitEnable == 1){
                break;
            }
        }
        //[NSThread sleepForTimeInterval:thisDelay];
    }
    
   // _testResult=@"PASS";
    
    if ([_testResult isEqualToString:@"PASS"]) {
        _passCount +=1;
    }else{
        _failCount +=1;
    }
    [self logUpdate:@"----------------Test Report-----------------"];
    NSString *msg=[NSString stringWithFormat:@"SN:%@ \nResult:%@",_snString,_testResult];
    [self logUpdate:msg];
    _TESTING_FLAG=NO;
    [self logUpdate:@"====================Main Test End=========================="];
    //save local log
    if(![self saveLocalLog:_logString]){
        [self showAlertViewWarning:@"Save local log FAIL!"];
    }
    //save csv
    //------csv data:_valuesData
    NSString *test_time=[self getCurrentTime];
    NSString *csvData=[NSString stringWithFormat:@"\n%@,%@,%@,%@,",_snString,_testResult,_failList,test_time];
    for (int i=0; i<[_tableData[TV_VALUE_INDEX] count]; i++) {
        csvData=[csvData stringByAppendingString:[_tableData[TV_VALUE_INDEX] objectAtIndex:i]];
        csvData=[csvData stringByAppendingString:@","];
    }
    //-----title line 1:item title
    NSString *csvTitle=@"SN,Result,FailList,TestTime,";
    for (int i=0; i<[_testPlanData[TP_TESTITEMS_INDEX] count]; i++) {
        csvTitle=[csvTitle stringByAppendingString:[_testPlanData[TP_TESTITEMS_INDEX] objectAtIndex:i]];
        csvTitle=[csvTitle stringByAppendingString:@","];
    }
    //-----title line 2:up value
    csvTitle=[csvTitle stringByAppendingString:@"\nUp----->,,,,"];
    for (int i=0; i<[_testPlanData[TP_UP_INDEX] count]; i++) {
        csvTitle=[csvTitle stringByAppendingString:[_testPlanData[TP_UP_INDEX] objectAtIndex:i]];
        csvTitle=[csvTitle stringByAppendingString:@","];
    }
    //-----title line 3:low value
    csvTitle=[csvTitle stringByAppendingString:@"\nLow----->,,,,"];
    for (int i=0; i<[_testPlanData[TP_LOW_INDEX] count]; i++) {
        csvTitle=[csvTitle stringByAppendingString:[_testPlanData[TP_LOW_INDEX] objectAtIndex:i]];
        csvTitle=[csvTitle stringByAppendingString:@","];
    }
    //-----title line 4:unit
    csvTitle=[csvTitle stringByAppendingString:@"\nUnit----->,,,,"];
    for (int i=0; i<[_testPlanData[TP_UNIT_INDEX] count]; i++) {
        csvTitle=[csvTitle stringByAppendingString:[_testPlanData[TP_UNIT_INDEX] objectAtIndex:i]];
        csvTitle=[csvTitle stringByAppendingString:@","];
    }
    //-----save funcation
    if (![self saveCsvWithTitle:csvTitle withData:csvData]) {
        [self showAlertViewWarning:@"Save local csv FAIL!"];
    }
}
-(BOOL)judgeValue:(NSString *)value low:(NSString *)theLow up:(NSString *)theUp{
    double thisValue=[value doubleValue];
    double thisLow=[theLow doubleValue];
    double thisUp=[theUp doubleValue];
    if ([theLow isEqualToString:@""] && [theUp isEqualToString:@""]) {
        return YES;
    }
    else if([theLow isEqualToString:@""]){
        return thisValue <= thisUp ? YES : NO;
    }else if([theUp isEqualToString:@""]){
        return thisValue >= thisLow ? YES : NO;
    }else{
        if (thisValue >= thisLow && thisValue <= thisUp) {
            return YES;
        }else{
            return NO;
        }
    }
}
//test timer track
-(void)testTimeTrack{
    int i=0;
    //通知主线程刷新
    dispatch_async(dispatch_get_main_queue(), ^{
        //回调或者说是通知主线程刷新，
        [self->_timerTF setStringValue:@"0s"];
        [self->_statusTF setStringValue:[NSString stringWithFormat:@"Testing..."]];
        [self->_statusTF setBackgroundColor:[NSColor systemYellowColor]];
        [self->_snTF setEnabled:NO];
        [self->_startBtn setEnabled:NO];
        [self->_cleanBtn setEnabled:NO];
        [self->_setPageBtn setEnabled:NO];
    });
    while(_TESTING_FLAG)
    {
        //NSLog(@"timer thread is still alive: %d(sec)", i);
        [NSThread sleepForTimeInterval:1.0];
        i++;
        //[durationCell setIntValue:i];
        //通知主线程刷新
        dispatch_async(dispatch_get_main_queue(), ^{
            //回调或者说是通知主线程刷新，
            [self->_timerTF setStringValue:[NSString stringWithFormat:@"%ds",i]];
        });
    }
    NSColor *color=[_testResult isEqualToString:@"PASS"] ?
    [NSColor systemGreenColor] : [NSColor systemRedColor];
    //通知主线程刷新
    dispatch_async(dispatch_get_main_queue(), ^{
        //回调或者说是通知主线程刷新，
        //[self->_statusLabel setStringValue:[NSString stringWithFormat:@"Done"]];
        //[self->_statusLabel setBackgroundColor:[NSColor systemGreenColor]];
        [self updateYield:YES];
        [self->_snTF setStringValue:@""];
        [self->_snTF setEnabled:YES];
        [self->_startBtn setEnabled:YES];
        [self->_snTF becomeFirstResponder];
        [self->_statusTF setStringValue:self->_testResult];
        [self->_statusTF setBackgroundColor:color];
        [self->_cleanBtn setEnabled:YES];
        [self->_setPageBtn setEnabled:YES];
        
    });
    
}
-(void)updateYield:(bool )save_flag{
    _inputCount = _failCount + _passCount;
    [_inputTF setStringValue:[NSString stringWithFormat:@"Input:%d",_inputCount]];
    [_passTF setStringValue:[NSString stringWithFormat:@"Pass:%d",_passCount]];
    [_failTF setStringValue:[NSString stringWithFormat:@"Fail:%d",_failCount]];
    NSString *yieldStr = @"Yield:0.00%";
    if(_inputCount != 0){
        float yield = (_passCount*1.0000/_inputCount) *100;
        yieldStr=[NSString stringWithFormat:@"Yield:%.2f",yield];
        yieldStr=[yieldStr stringByAppendingString:@"%"];
        [_yieldTF setStringValue:yieldStr];
    }else{
        [_yieldTF setStringValue:yieldStr];
    }
    NSLog(@"input:%d pass:%d fail:%d yield:%@",_inputCount,_passCount,_failCount,yieldStr);
    if(save_flag){
        _testSet =[_rootSet objectForKey:@"yield"];
        [_testSet setValue:[NSNumber numberWithInt:_inputCount] forKey:@"Input"];
        [_testSet setValue:[NSNumber numberWithInt:_passCount] forKey:@"Pass"];
        [_rootSet setValue:_testSet forKey:@"yield"];
        NSString *portFilePath=[[NSBundle mainBundle] resourcePath];
        portFilePath =[portFilePath stringByAppendingPathComponent:_testConfigFile];
        [_rootSet writeToFile:portFilePath atomically:NO];
    }
}
-(void)logUpdate:(NSString *)log{
    [_lock lock];
    NSDateFormatter *dateFormat=[[NSDateFormatter alloc] init];
    [dateFormat setDateStyle:NSDateFormatterMediumStyle];
    [dateFormat setDateStyle:NSDateFormatterShortStyle];
    [dateFormat setDateFormat:@"[yyyy-MM-dd HH:mm:ss.SSS]"];
    
    NSString *dateText=[NSString string];
    dateText=[dateFormat stringFromDate:[NSDate date]];
    //dateText=[dateText stringByAppendingString:@"\n"];
    //_logString = [_logString stringByAppendingString:@"\r\n==============================\r\n"];
    _logString = [_logString stringByAppendingString:dateText];
    _logString = [_logString stringByAppendingString:log];
    _logString = [_logString stringByAppendingString:@"\r\n"];
    
    [self performSelectorOnMainThread:@selector(addLogOnMainThread) withObject:nil waitUntilDone:YES];
    //if([self._logString length] >10000) self._logString=@"";
    NSLog(@"%@",log);
    [_lock unlock];
}
-(void)addLogOnMainThread{
    [_logView setString:_logString];
    [_logView scrollRangeToVisible:NSMakeRange([[_logView textStorage] length],0)];
    [_logView setNeedsDisplay: YES];
}
//show information window
-(long)showPanel:(NSString *)thisEnquire{
    NSLog(@"start run panel window");
    NSAlert *theAlert=[[NSAlert alloc] init];
    [theAlert addButtonWithTitle:@"OK"]; //1000
    [theAlert setMessageText:@"Info"];
    [theAlert setInformativeText:thisEnquire];
    [theAlert setAlertStyle:0];
    //[theAlert setIcon:[NSImage imageNamed:@"Check_yes_256px.png"]];
    NSLog(@"End run panel window");
    return [theAlert runModal];
}
//更新tableview行颜色
- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    if([_tableData[TV_STATUS_INDEX] count]>rowIndex)
    {
        NSString *colorTag=[_tableData[TV_STATUS_INDEX] objectAtIndex:rowIndex];
        if([colorTag isEqualToString:@"FAIL"])
        {
            [aCell setDrawsBackground:1];
            [aCell setBackgroundColor:[NSColor redColor]];
            
        }
        else if([colorTag isEqualToString:@"SKIPPED"])
        {
            
            [aCell setDrawsBackground:1];
            [aCell setBackgroundColor:[NSColor grayColor]];
            
        }
        else if([colorTag isEqualToString:@"PASS"])
        {
            
            [aCell setDrawsBackground:1];
            [aCell setBackgroundColor:[NSColor greenColor]];
            
        }
        else if([colorTag isEqualToString:@"Test..."])
        {
            
            [aCell setDrawsBackground:1];
            [aCell setBackgroundColor:[NSColor yellowColor]];
            
        }
        else {
            [aCell setDrawsBackground:1];
            [aCell setBackgroundColor:[NSColor whiteColor]];
        }
    }
    else
    {
        [aCell setDrawsBackground:1];
        [aCell setBackgroundColor:[NSColor whiteColor]];
    }
}

//tableView datasource
- (int)numberOfRowsInTableView: (NSTableView *)aTableView
{
    return (int)[_tableData[TV_ITEM_INDEX] count];
}

- (id)tableView: (NSTableView *)aTableView
objectValueForTableColumn: (NSTableColumn *)aTableColumn
            row: (int)rowIndex
{
    NSString *identifier=[aTableColumn identifier];
    
    if([identifier isEqualToString:@"No"]){
        return [NSString stringWithFormat:@"%d",rowIndex+1];
    }
    else if([identifier isEqualToString:@"Items"]){
        return [_tableData[TV_ITEM_INDEX] objectAtIndex:rowIndex];
        
    }
    else if([identifier isEqualToString:@"Status"]){
        
        int tt=(int)[_tableData[TV_STATUS_INDEX] count];
        if(tt>rowIndex){
            return [_tableData[TV_STATUS_INDEX] objectAtIndex:rowIndex];
            
        }
        else{
            return @"";
            
        }
    }
    else if([identifier isEqualToString:@"Value"]){
        
        int tt=(int)[_tableData[TV_VALUE_INDEX] count];
        if(tt>rowIndex){
            return [_tableData[TV_VALUE_INDEX] objectAtIndex:rowIndex];
            
        }
        else{
            return @"";
            
        }
    }
    else if([identifier isEqualToString:@"Low"]){
        return [_tableData[TV_LOW_INDEX] objectAtIndex:rowIndex];
        
    }
    else if([identifier isEqualToString:@"Refer"]){
        return [_tableData[TV_REFERENCE_INDEX] objectAtIndex:rowIndex];
        
    }
    else if([identifier isEqualToString:@"Up"]){
        return [_tableData[TV_UP_INDEX] objectAtIndex:rowIndex];
        
    }
    else if([identifier isEqualToString:@"Unit"]){
        return [_tableData[TV_UNIT_INDEX] objectAtIndex:rowIndex];
        
    }
    else if([identifier isEqualToString:@"Duration"]){
        
        int tt=(int)[_tableData[TV_DURATION_INDEX] count];
        if(tt>rowIndex){
            return [_tableData[TV_DURATION_INDEX] objectAtIndex:rowIndex];
            
        }
        else{
            return @"";
            
        }
    }
    else{
        
        return @"";
    }
    
}
//tableView 界面更新
-(void)updateTable{
    [_tableView scrollRowToVisible:_rowRefresh];
    [_tableView display];
}

-(BOOL)checkRouterWithSN:(NSString *)strSN
{
    //    strStation = @"ITKS_A02-2FAP-01_3_CON-OQC";
    static BOOL bResult = false;
    //创建信号量,实现同步请求
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    NSURLSession *session=[NSURLSession sharedSession];
    //第一步，创建URL
    //第一步，创建URL
    NSString *strUrl = @"";//[self GetGHDValueWithKey:@"SFC_URL"];
    //NSString *urlString=@"http://10.37.66.2:8005/LuxShare_QualityTestService.aspx";
    //第二步，创建请求
    NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:strUrl]];
    
    [request setHTTPMethod:@"POST"];
    [request setTimeoutInterval:5.0f];
    //request.HTTPMethod=@"GET";
    //NSString *strData = [NSString stringWithFormat:@"c=QUERY_RECORD&sn=%@&StationID=%@&cmd=QUERY_PANEL", strSN, strStation];
    NSString *strStation=@"";//[self GetGHDValueWithKey:@"STATION_ID"];
    NSString *strBody = [NSString stringWithFormat:@"c=QUERY_RECORD&sn=%@&tsid=%@&p=UNIT_PROCESS_CHECK", strSN, strStation];
    [request setHTTPBody:[strBody dataUsingEncoding:NSUTF8StringEncoding]];
    
    //第三步，连接服务器
    NSString static *strReceivedData;
    NSURLSessionDataTask *task=[session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        strReceivedData = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        strReceivedData=[strReceivedData stringByReplacingOccurrencesOfString:@";" withString:@"\r\n"];
        NSString *strError=[NSString stringWithFormat:@"error:%@",error];
        NSLog(@"%@",strError);
        if(![strError isEqual:@"error:(null)"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                //通知主线程更新
                [self showAlertViewWarning:@"Connect to PDCA error!"];
            });
            
            bResult = false;
        }else{
            NSString *strSubStr = @"unit_process_check=";
            if([strReceivedData containsString:strSubStr])
            {
                NSRange rang = [strReceivedData rangeOfString:strSubStr];
                NSString *strMsg = [strReceivedData substringFromIndex:(rang.location + rang.length)];
                if([strMsg isEqualToString:@"OK"])
                {
                    bResult = true;
                }
                else
                {
                    NSString *strErrMsg = @"";
                    strSubStr = @"UNIT OUT OF PROCESS ";
                    rang = [strMsg rangeOfString:strSubStr];
                    strErrMsg = [strMsg substringFromIndex:(rang.location + rang.length)];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        //通知主线程更新
                        [self showAlertViewWarning:strErrMsg];
                    });
                    
                    bResult = false;
                }
            }
            else
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    //通知主线程更新
                    [self showAlertViewWarning:[NSString stringWithFormat:@"Response error:%@",strReceivedData]];
                });
                
                bResult = false;
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            //通知主线程更新
            [self logUpdate:strReceivedData];
        });
        
        //NSLog(@"%@",strReceivedData);
        //发送 signal
        dispatch_semaphore_signal(semaphore);
    }];
    
    [task resume];
    //等待(阻塞线程)
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    NSLog(@"task finish");
    return bResult;
}
- (void)showAlertViewWarning:(NSString *)strWarning
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    [alert setMessageText:strWarning];
    [alert setAlertStyle:NSAlertStyleWarning];
    [alert runModal];
}
-(time_t)converTime2Stamp:(NSString *)strTime
{
    NSDate *dataTime = [self getDateFromString:strTime];
    time_t unixTime = (time_t) [dataTime timeIntervalSince1970];
    return unixTime;
}

-(NSDate *)getDateFromString:(NSString *)pstrDate
{
    NSDateFormatter *df1 = [[NSDateFormatter alloc] init];
    [df1 setDateFormat:@"yyyy.MM.dd-HH.mm.ss"];
    NSDate *dtPostDate = [df1 dateFromString:pstrDate];
    return dtPostDate;
}
-(NSString *)getYearMonth
{
    NSDate *today = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"YYYY_MM"];
    NSString *currentTime = [dateFormatter stringFromDate:today];
    return currentTime;
}
- (NSString *) getCurrentDate
{
    NSDate *today = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"YYYY_MM_dd"];
    NSString *currentTime = [dateFormatter stringFromDate:today];
    return currentTime;
}

- (NSString *)getCurrentTime
{
    NSDate *today = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"YYYY/MM/dd HH:mm:ss"];
    NSString *currentTime = [dateFormatter stringFromDate:today];
    return currentTime;
}
- (NSString *)getTimeSuffix
{
    NSDate *today = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"YYYYMMddHHmmss"];
    NSString *currentTime = [dateFormatter stringFromDate:today];
    return currentTime;
}
//Save local csv
-(BOOL)saveCsvWithTitle:(NSString *)title withData:(NSString *)data{
    NSString *strMonth = [self getYearMonth];
    NSString *strDate=[self getCurrentDate];
    NSString *logPath = [NSString stringWithFormat:@"/vault/%@/CSVLog/%@",_swName,strMonth];
    NSString *strFileName = [NSString stringWithFormat:@"%@.csv", strDate];
    NSString *strFilePath = [NSString stringWithFormat:@"%@/%@", logPath, strFileName];
    if(YES == [self createLOGFileWithPath:logPath withFilePath:strFilePath withTitle:title])
    {
        return [self appendDataToFileWithString:data withFilePath:strFilePath];
    }else{
        return NO;
    }
}
//Save local log.txt
-(BOOL)saveLocalLog:(NSString *)log{
    NSString *strMonth = [self getYearMonth];
    NSString *strDate=[self getCurrentDate];
    NSString *logPath = [NSString stringWithFormat:@"/vault/%@/LocalLog/%@/%@",_swName,strMonth,strDate];
    NSString *strTimeSuffix = [self getTimeSuffix];
    NSString *strFileName = [NSString stringWithFormat:@"%@_%@.log", _snString,strTimeSuffix];
    NSString *strFilePath = [NSString stringWithFormat:@"%@/%@", logPath, strFileName];
    NSString *title=@"-------------local log---------------";
    if(YES == [self createLOGFileWithPath:logPath withFilePath:strFilePath withTitle:title])
    {
        return [self appendDataToFileWithString:log withFilePath:strFilePath];
    }else{
        return NO;
    }
}
-(BOOL)createLOGFileWithPath:(NSString *)path withFilePath:(NSString *)strLogFilePath withTitle:(NSString *)title
{
    BOOL isDir = NO;
    NSError *errMsg;
    
    //1. Get execution tool's folder path
    NSFileManager *fm = [NSFileManager defaultManager];
    
    //2. If bDirExist&isDir are true, the directory exit
    BOOL bDirExist = [fm fileExistsAtPath:path isDirectory:&isDir];
    if (!(bDirExist == YES && isDir == YES))
    {
        if (NO == [fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&errMsg])
            return NO;
    }
    
    //4. Check file exist or not
    //5. If file not exist, creat data to file
    //    bDirExist = [fm fileExistsAtPath:_logFilePath isDirectory:&isDir];
    if (NO == [fm fileExistsAtPath:strLogFilePath isDirectory:&isDir])
    {
        if (NO == [fm createFileAtPath:strLogFilePath contents:nil attributes:nil])
        {
            return NO;
        }
        
        NSString *strSum = [[NSString alloc] init];
        if (NO == [strSum writeToFile:strLogFilePath atomically:YES encoding:NSUTF8StringEncoding error:&errMsg])
        {
            return NO;
        }
        //NSString *strTitle=[self getCsvTitle];
        [self appendDataToFileWithString:title withFilePath:strLogFilePath];//第一次创建时，增加INFO
    }
    
    return YES;
}
- (BOOL)appendDataToFileWithString:(NSString *)string withFilePath:(NSString *)strFilePath
{
    NSFileHandle *myHandle = [NSFileHandle fileHandleForWritingAtPath:strFilePath];
    [myHandle seekToEndOfFile];
    [myHandle writeData:[string dataUsingEncoding:NSUTF8StringEncoding]];
    [myHandle closeFile];
    
    return YES;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

-(BOOL)windowShouldClose:(id)sender{
    [self logUpdate:@"window will close..."];
    _exitView=[[ExitView alloc] initWithNibName:@"ExitView" bundle:nil];
    _exitView.delegate=self;
    [_mainVC presentViewControllerAsModalWindow:_exitView];
    NSLog(@"show exit view done.");
    return NO;
}

- (void)msgFromExitView:(NSString *)msg {
    NSString *log=[NSString stringWithFormat:@"msg:%@ from exit view",msg];
    [self logUpdate:log];

    if ([msg isEqualToString:@"EXIT"]) {
        [self performSelectorInBackground:@selector(exitProgramThread) withObject:nil];
    }
    else{
        [_exitView closeView];
    }
}
-(void)exitProgramThread{
    [_exitView updateExitStatus:@"Init...OK" progressValue:40];
    [NSThread sleepForTimeInterval:0.5];
    //release ttConfig socket connect
    [_configView sendCmd:@"exit" TimeOut:2.0 withName:@"PYClient"];
    [NSThread sleepForTimeInterval:0.5];
    [_exitView updateExitStatus:@"Python service shutdown...OK" progressValue:70];
    [NSThread sleepForTimeInterval:0.5];
    [_configView closeDevices];
    [_exitView updateExitStatus:@"TT devices close...OK" progressValue:100];
    [NSThread sleepForTimeInterval:0.5];
    [_exitView closeView];
    [NSApp terminate:self];
}

@end
