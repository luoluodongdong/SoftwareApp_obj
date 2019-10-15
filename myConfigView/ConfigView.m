//
//  ConfigView.m
//  TT_ICT
//
//  Created by Weidong Cao on 2019/6/11.
//  Copyright © 2019 曹伟东. All rights reserved.
//

#import "ConfigView.h"

@implementation MY_DEVICE

-(NSString *)sendCmd:(NSString *)thisCommand withTimeOut:(double)thisTimeOut{
    NSString *response=@"";
    if ([_Type isEqualToString:@"SERIAL"] ) {
        BOOL isTimeOut=[_serial sendCmd:thisCommand received:&response withTimeOut:thisTimeOut];
        if (isTimeOut) {
            return @"TIMEOUT";
        }else{
            return response;
        }
    }
    else if([_Type isEqualToString:@"INSTR"]){
        NSString *response=[_instrument queryInstr:thisCommand];
        if ([response isEqualToString:@""]) {
            return @"TIMEOUT";
        }else{
            return response;
        }
    }
    else if([_Type isEqualToString:@"SOCKET"]){
        _socket.timeout=thisTimeOut;
        response=[_socket query:thisCommand];
        if ([response isEqualToString:@""]) {
            return @"TIMEOUT";
        }else{
            return response;
        }
    }
    return @"";
}
-(void)closeDevice{
    if ([_Type isEqualToString:@"SERIAL"]) {
        //Serial port
        if (_serial.serialPort.isOpen) {
            [_serial.serialPort close];
        }
    }
    else if([_Type isEqualToString:@"INSTR"]){
        //visa panel
        [_instrument closeInstrument];
        
    }
    else if([_Type isEqualToString:@"SOCKET"]){
        //socket panel
        [_socket stopSocket];
        
    }
}
@end

@interface myConfigView ()

//@property (nonatomic,strong) MySerialPanel *mySerialPanel;
@property (nonatomic,strong) NSString *configPlist;
@property (nonatomic,strong) NSDictionary *rootSet;
@property (nonatomic,strong) NSDictionary *ConfigDict;
@property (nonatomic,strong) NSMutableDictionary *devicesDic;
//@property (atomic,strong) NSString *recData;

@end

@implementation myConfigView

- (void)viewDidLoad {
    [super viewDidLoad];
    NSString *desc=[NSString stringWithFormat:@"%@ Config View",_dictKey];
    [backBtn setToolTip:@"Return Main View"];
    [self setTitle:desc];
    [self.view setAutoresizesSubviews:NO];
    [devicesPopBtn removeAllItems];
    NSString *rawfilePath=[[NSBundle mainBundle] resourcePath];
    NSString *filePath;
    filePath=[rawfilePath stringByAppendingPathComponent:_configPlist];
    _rootSet=[[NSDictionary alloc] initWithContentsOfFile:filePath];
    //NSString *slot_key=[NSString stringWithFormat:@"Slot-%d",self.slot_ID];
    
    _ConfigDict=[_rootSet objectForKey:_dictKey];
    NSArray *keysArr=[_ConfigDict allKeys];
    for (NSString *key in keysArr) {
        NSDictionary *dev=[_ConfigDict objectForKey:key];
        BOOL dev_enable=[[dev objectForKey:@"Enable"] boolValue];
        if (NO == dev_enable) {
            continue;
        }
        [devicesPopBtn addItemWithTitle:key];
    }
}

-(void)initView{
    //configVC=[[NSViewController alloc] init];
    _devicesDic=[[NSMutableDictionary alloc] initWithCapacity:1];
    
    _configPlist=@"StationCfg.plist";
    NSString *rawfilePath=[[NSBundle mainBundle] resourcePath];
    NSString *filePath;
    filePath=[rawfilePath stringByAppendingPathComponent:_configPlist];
    _rootSet=[[NSDictionary alloc] initWithContentsOfFile:filePath];
    //NSString *slot_key=[NSString stringWithFormat:@"Slot-%d",self.slot_ID];
    _ConfigDict=[_rootSet objectForKey:_dictKey];
    
    NSArray *keysArr=[_ConfigDict allKeys];
    NSLog(@"my config keys:%@",keysArr);
    BOOL ALL_DEVICES_IS_READY = YES;
    for (NSString *key in keysArr) {
        NSDictionary *dev=[_ConfigDict objectForKey:key];
        MY_DEVICE *myDevice=[[MY_DEVICE alloc] init];
        myDevice.Name=[dev objectForKey:@"Name"];
        myDevice.Desctription=[dev objectForKey:@"Description"];
        myDevice.Enable=[[dev objectForKey:@"Enable"] boolValue];
        myDevice.ID=[[dev objectForKey:@"ID"] intValue];
        myDevice.Type=[dev objectForKey:@"Type"];
        
        if (NO == myDevice.Enable) {
            continue;
        }
        
        if ([myDevice.Type isEqualToString:@"SERIAL"]) {
            myDevice.Addr=[dev objectForKey:@"Addr"];
            myDevice.BaudRate=[[dev objectForKey:@"BaudRate"] intValue];
            //*****************Serialport Pannel 1**************//
            MySerialPanel *mySerialPanel=[[MySerialPanel alloc] initWithNibName:@"mySerialPanel" bundle:nil];
            mySerialPanel._description=myDevice.Desctription;
            mySerialPanel._id=myDevice.ID;
            mySerialPanel.delegate=self;
            //_mySerialPanel.serialPort.usesRTSCTSFlowControl=TRUE;
            //_mySerialPanel.serialPort.usesDTRDSRFlowControl=TRUE;
            [mySerialPanel initView];
            BOOL result=[mySerialPanel autoOpenSerial:myDevice.Addr baud:myDevice.BaudRate];
            NSLog(@"auto open serial result:%hhd",result);
            if (!result) {
                NSLog(@"Auto open serial fail!");
                ALL_DEVICES_IS_READY = NO;
                [self alarmPanel:[NSString stringWithFormat:@"[%@]Auto Open %@ port error!",_dictKey,myDevice.Addr]];
            }
            //PIN status output
            mySerialPanel.serialPort.DTR=TRUE;
            //_mySerialPanel.serialPort.RTS=TRUE;
            //******************End***************************//
            myDevice.isOpened = result;
            myDevice.serial=mySerialPanel;
            [_devicesDic setObject:myDevice forKey:myDevice.Name];
        }
        else if([myDevice.Type isEqualToString:@"INSTR"]){
            myDevice.Addr=[dev objectForKey:@"Addr"];
            myDevice.BaudRate=[[dev objectForKey:@"BaudRate"] intValue];
            
            MyVisaPanel *myVisaPanel=[[MyVisaPanel alloc] initWithNibName:@"myVisaPanel" bundle:nil];
            myVisaPanel._description=myDevice.Desctription;
            myVisaPanel._id=myDevice.ID;
            myVisaPanel.delegate=self;
            [myVisaPanel initView];
            
            BOOL result=[myVisaPanel autoOpenInstrument:myDevice.Addr timeout:2000];
            if (!result) {
                NSLog(@"Auto open instrument fail!");
                ALL_DEVICES_IS_READY = NO;
                [self alarmPanel:[NSString stringWithFormat:@"[%@]Auto Open %@ instrument error!",_dictKey,myDevice.description]];
            }
            myDevice.isOpened = result;
            myDevice.instrument=myVisaPanel;
            [_devicesDic setObject:myDevice forKey:myDevice.Name];
            
        }
        else if([myDevice.Type isEqualToString:@"SOCKET"]){
            myDevice.IP=[dev objectForKey:@"IP"];
            myDevice.Port=[[dev objectForKey:@"Port"] intValue];
            NSString *dev_mode=[dev objectForKey:@"Mode"];
            
            //******************Socket Panel***************************//
            MySocketPanel *mySocketPanel=[[MySocketPanel alloc] initWithNibName:@"mySocketPanel" bundle:nil];
            mySocketPanel._description=myDevice.Desctription;
            mySocketPanel._id=myDevice.ID;
            mySocketPanel.delegate=self;
            mySocketPanel.mode=dev_mode;
            mySocketPanel.timeout=2.0;
            [mySocketPanel initView];
            BOOL result=[mySocketPanel autoStartSocket:myDevice.IP port:myDevice.Port];
            if (!result) {
                ALL_DEVICES_IS_READY = NO;
                [self alarmPanel:[NSString stringWithFormat:@"[%@]Auto Open %@ port error!",_dictKey,myDevice.Desctription]];
            }
            //******************End***************************//
            myDevice.isOpened = result;
            myDevice.socket=mySocketPanel;
            [_devicesDic setObject:myDevice forKey:myDevice.Name];
        }
        
    }
    
    if (YES == ALL_DEVICES_IS_READY) {
        [self.delegate msgFromConfigView:@"STATUS:1"];
    }else{
        [self.delegate msgFromConfigView:@"STATUS:0"];
    }
    
}
//close all opened devices
-(void)closeDevices{
    NSLog(@"closeDevices working...");
    NSArray *dev_keys=[_devicesDic allKeys];
    for(NSString *item in dev_keys){
        MY_DEVICE *myDevice=[_devicesDic objectForKey:item];
        [myDevice closeDevice];
    }
}
//return unit view
-(IBAction)backBtnAction:(id)sender{
    [self.delegate msgFromConfigView:@"Close ConfigView"];
    
    [self dismissViewController:self];
}

-(IBAction)devicesPopBtnAction:(id)sender{
    
    NSString *click_key=[[devicesPopBtn selectedItem] title];
    NSLog(@"PopUpBtn selected:%@",click_key);
    NSDictionary *dev=[_ConfigDict objectForKey:click_key];
    NSString *dev_name=[dev objectForKey:@"Name"];
    NSString *dev_type=[dev objectForKey:@"Type"];
    
    MY_DEVICE *myDevice=[_devicesDic objectForKey:dev_name];
    if ([dev_type isEqualToString:@"SERIAL"]) {
        [configVC presentViewControllerAsSheet:myDevice.serial];
    }
    else if([dev_type isEqualToString:@"INSTR"]){
        [configVC presentViewControllerAsSheet:myDevice.instrument];
    }
    else if([dev_type hasSuffix:@"SOCKET"]){
        [configVC presentViewControllerAsSheet:myDevice.socket];
    }
    else{
        NSString *msg=[NSString stringWithFormat:@"Error:unkown device:%@ Please check DevicesConfig.plist!",dev_type];
        [self alarmPanel:msg];
    }
}
//send cmd with timeout,return response string
-(NSString *)sendCmd:(NSString *)thisCommand TimeOut:(double)thisTimeOut withName:(NSString *)name{
    MY_DEVICE *myDevice=[_devicesDic objectForKey:name];
    return [myDevice sendCmd:thisCommand withTimeOut:thisTimeOut];
}
#pragma mySerialPanel delegate event
//receive data
- (void)receivedDataEvent:(NSString *)data id:(int)myID {
    //NSLog(@"id:%d rec data:%@",myID,data);
    //_recData=[_recData stringByAppendingString:data];
}
//save config info---serial/instrument/socket
-(BOOL)saveConfigEvent:(NSDictionary *)info{
    NSString *dev_type=[info objectForKey:@"Type"];
    int myID = [[info objectForKey:@"ID"] intValue];
    int index = myID / 1000;
    NSString *dev_key=[NSString stringWithFormat:@"Device%d",index];
    NSDictionary *dev_dic=[_ConfigDict objectForKey:dev_key];
    NSString *dev_name=[dev_dic objectForKey:@"Name"];
    if ([dev_type isEqualToString:@"SERIAL"]) {
        [dev_dic setValue:[info objectForKey:@"Addr"] forKey:@"Addr"];
        [dev_dic setValue:[info objectForKey:@"BaudRate"] forKey:@"BaudRate"];
    }
    else if([dev_type isEqualToString:@"INSTR"]){
        [dev_dic setValue:[info objectForKey:@"Addr"] forKey:@"Addr"];
    }
    else if([dev_type isEqualToString:@"SOCKET"]){
        [dev_dic setValue:[info objectForKey:@"Mode"] forKey:@"Mode"];
        [dev_dic setValue:[info objectForKey:@"IP"] forKey:@"IP"];
        [dev_dic setValue:[info objectForKey:@"Port"] forKey:@"Port"];
    }
    [_ConfigDict setValue:dev_dic forKey:dev_key];
    //NSString *slot_key=[NSString stringWithFormat:@"Slot-%d",self.slot_ID];
    [_rootSet setValue:_ConfigDict forKey:_dictKey];
    NSString *portFilePath=[[NSBundle mainBundle] resourcePath];
    portFilePath =[portFilePath stringByAppendingPathComponent:_configPlist];
    [_rootSet writeToFile:portFilePath atomically:NO];
    
    MY_DEVICE *myDevice=[_devicesDic objectForKey:dev_name];
    myDevice.isOpened = YES;
    [_devicesDic setObject:myDevice forKey:dev_name];
    BOOL all_devices_is_ready = YES;
    for (MY_DEVICE *myDev in [_devicesDic allValues]) {
        if (!myDev.isOpened) {
            all_devices_is_ready = NO;
            break;
        }
    }
    if (all_devices_is_ready) {
        //send "ok" msg to unit/TT view
        [self.delegate msgFromConfigView:@"STATUS:1"];
    }else{
        //send "ng" msg to unit/TT view
        [self.delegate msgFromConfigView:@"STATUS:0"];
    }
    
    return YES;
}
- (void)send2Unit_Config:(NSString *)config {
    
}

- (BOOL)commitEditingAndReturnError:(NSError * _Nullable __autoreleasing * _Nullable)error {
    return YES;
}

- (void)encodeWithCoder:(nonnull NSCoder *)aCoder {
    
}
//alarm information display
-(long)alarmPanel:(NSString *)thisEnquire{
    NSLog(@"start run alarm window");
    NSAlert *theAlert=[[NSAlert alloc] init];
    [theAlert addButtonWithTitle:@"OK"]; //1000
    [theAlert setMessageText:@"Error!"];
    [theAlert setInformativeText:thisEnquire];
    [theAlert setAlertStyle:0];
    [theAlert setIcon:[NSImage imageNamed:@"Error_256px_5.png"]];
    NSLog(@"End run alarm window");
    return [theAlert runModal];
}
#pragma socket panel delegate event
- (void)msgFromConfigView:(NSString *)msg {
    
}

- (void)debugPrint:(NSString *)log withID:(int)myID {
    
}

- (NSString *)reply:(NSString *)request {
    return @"";
}



@end
