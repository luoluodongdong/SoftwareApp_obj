//
//  AppDelegate.h
//  SoftwareApp
//
//  Created by 曹伟东 on 2019/3/29.
//  Copyright © 2019年 曹伟东. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "parseCSV.h"
#import "ConfigView.h"
#import "MEShelper.h"
#import "welcomeView.h"
#import "ExitView.h"
#import "myPassWord.h"

@interface AppDelegate : NSObject <NSApplicationDelegate,ConfigViewDelegate,WelcomeViewDelegate,ExitViewDelegate,PassWordDelegate>
{
    IBOutlet NSViewController *_mainVC;
    //menu item
    //IBOutlet NSMenuItem *_serialportMI;
    //IBOutlet NSMenuItem *_instr34970MI;
    //home page
    IBOutlet NSTextField *_swNameTF;
    IBOutlet NSTextField *_verTF;
    IBOutlet NSButton *_homePageBtn;
    IBOutlet NSButton *_logPageBtn;
    IBOutlet NSButton *_setPageBtn;
    
    IBOutlet NSTabView *_mainTabView;
    
    IBOutlet NSTableView *_tableView;
    IBOutlet NSTextField *_snTF;
    IBOutlet NSTextField *_timerTF;
    IBOutlet NSButton *_startBtn;
    
    IBOutlet NSTextField *_inputTF;
    IBOutlet NSTextField *_passTF;
    IBOutlet NSTextField *_failTF;
    IBOutlet NSTextField *_yieldTF;
    IBOutlet NSButton *_cleanBtn;
    
    IBOutlet NSTextField *_statusTF;
    //log page
    IBOutlet NSTextView *_logView;

    IBOutlet NSTextField *_auditLabel;
    
    //set page
    IBOutlet NSButton *_devCfgBtn;
    IBOutlet NSPopUpButton *_modeBtn;
    
    
}

-(IBAction)goHomeBtnAction:(id)sender;
-(IBAction)goLogBtnAction:(id)sender;
-(IBAction)goSetBtnAction:(id)sender;
-(IBAction)startBtnAction:(id)sender;
-(IBAction)cleanBtnAction:(id)sender;
-(IBAction)scanSnAction:(id)sender;

-(IBAction)devCfgBtnAction:(id)sender;
-(IBAction)modeBtnAction:(id)sender;

@end

