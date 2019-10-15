//
//  ConfigView.h
//  TT_ICT
//
//  Created by Weidong Cao on 2019/6/11.
//  Copyright © 2019 曹伟东. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <mySerial/mySerialPanel.h>
#import "myVisaPanel.h"
#import "mySocketPanel.h"

@protocol ConfigViewDelegate<NSObject>

-(void)msgFromConfigView:(NSString *)msg;

@end

@interface myConfigView : NSViewController<ConfigViewDelegate,SerialPanelDelegate,VisaPanelDelegate,SocketPanelDelegate>
{
    IBOutlet NSButton *backBtn;
    IBOutlet NSPopUpButton *devicesPopBtn;
    IBOutlet NSViewController *configVC;
}

@property (nonatomic,weak) id<ConfigViewDelegate> delegate;
@property (nonatomic,strong) NSString *dictKey;

-(void)initView;
-(void)closeDevices;

/*DUT serial port*/
//thiCommand:send a Command
//thisTimeOut:received data until "\n"
//return: received data (if timeout,will be "TIMEOUT")
-(NSString *)sendCmd:(NSString *)thisCommand TimeOut:(double )thisTimeOut withName:(NSString *)name;

-(IBAction)backBtnAction:(id)sender;

-(IBAction)devicesPopBtnAction:(id)sender;

@end
//封装一个device类
@interface MY_DEVICE : NSObject
@property (nonatomic,strong) NSString *Desctription;
@property (nonatomic,strong) NSString *Name;
@property (nonatomic,assign) BOOL Enable;
@property (nonatomic,assign) int ID;
@property (nonatomic,strong) NSString *Type;
@property (nonatomic,strong) NSString *Addr;
@property (nonatomic,assign) int BaudRate;
@property (nonatomic,strong) NSString *Mode;
@property (nonatomic,strong) NSString *IP;
@property (nonatomic,assign) int Port;
@property (nonatomic,assign) BOOL isOpened;
@property (nonatomic,strong) MySerialPanel *serial;
@property (nonatomic,strong) MyVisaPanel *instrument;
@property (nonatomic,strong) MySocketPanel *socket;
//声明device类方法
-(NSString *)sendCmd:(NSString *)thisCommand withTimeOut:(double)thisTimeOut;
-(void)closeDevice;

@end
