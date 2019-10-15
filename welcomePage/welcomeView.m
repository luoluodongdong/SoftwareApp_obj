//
//  welcomeView.m
//  welcomeWinTest
//
//  Created by Weidong Cao on 2019/6/23.
//  Copyright © 2019 Weidong Cao. All rights reserved.
//

#import "welcomeView.h"

@implementation welcomeView

- (id)initWithWindow:(NSWindow *)window
{
    NSLog (@"init()");
    
    self = [super initWithWindow:window];
    
    if (self)
    {
        
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    [[self.window standardWindowButton:NSWindowMiniaturizeButton] setHidden:YES];
    [[self.window standardWindowButton:NSWindowZoomButton] setHidden:YES];
    loginBox.contentView.wantsLayer = YES;
    [loginBox setBorderColor:[NSColor blueColor]];
    loginBox.contentView.layer.backgroundColor = [NSColor lightGrayColor].CGColor;
    [keyTF setEnabled:NO];
    [statusTF setHidden:YES];
    [statusPI setHidden:YES];
    NSString *msg=[NSString stringWithFormat:@"autoLogin:%hhd",self.autoLogin];
    [self.delegate msgFromWelcomeView:msg];
    if (self.autoLogin) {
        [self beginLoadMainForm];
    }
    NSLog(@"welcome window did load");
}
-(void)updateStatus:(NSString *)status progress:(double)value{
    if(value >100.0) value=100.0;
    dispatch_async(dispatch_get_main_queue(), ^{
        //通知主线程更新
        [self->statusTF setStringValue:status];
        [self->statusPI setDoubleValue:value];
    });
    
}
-(void)closePage{
    dispatch_async(dispatch_get_main_queue(), ^{
        //通知主线程更新
        [super close];
    });
}
-(IBAction)userTFaction:(id)sender{
    NSLog(@"enter user textfield");
    NSString *inputUser=[userTF stringValue];
    if(self.autoLogin) return;
    if ([inputUser length] == 0 ) {
        [self alarmPanel:@"User name is empty!"];
        [userTF becomeFirstResponder];
        
        return;
    }
    if (![inputUser isEqualToString:self.userName]) {
        [self alarmPanel:@"User name error!"];
        [userTF setStringValue:@""];
        [userTF becomeFirstResponder];
        return;
    }
    [keyTF setEnabled:YES];
    [keyTF becomeFirstResponder];
    
}
-(IBAction)loginBtnAction:(id)sender{
    NSLog(@"enter login btn");
    NSString *inputUser=[userTF stringValue];
    NSString *inputPassWord=[keyTF stringValue];
    if ([inputPassWord length] == 0) return;
    if ([inputUser length] == 0 ) {
        [self alarmPanel:@"User name is empty!"];
        [userTF becomeFirstResponder];
        return;
    }
    if (![inputUser isEqualToString:self.userName]) {
        [self alarmPanel:@"User name error!"];
        [userTF setStringValue:@""];
        [userTF becomeFirstResponder];
        return;
    }
    if (![inputPassWord isEqualToString:self.passWord]) {
        [self alarmPanel:@"Password error!"];
        [keyTF setStringValue:@""];
        [keyTF becomeFirstResponder];
        return;
    }
    [self beginLoadMainForm];
    
}
-(void)beginLoadMainForm{
    //[self.window  ]
    [[self.window standardWindowButton:NSWindowCloseButton] setEnabled:NO];
    [loginBox setHidden:YES];
    [statusTF setHidden:NO];
    [statusPI setHidden:NO];
    [self.delegate msgFromWelcomeView:@"login"];
}
//alarm information display
-(long)alarmPanel:(NSString *)thisEnquire{
    NSLog(@"start run alarm window");
    NSAlert *theAlert=[[NSAlert alloc] init];
    [theAlert addButtonWithTitle:@"OK"]; //1000
    [theAlert setMessageText:@"Error!"];
    [theAlert setInformativeText:thisEnquire];
    [theAlert setAlertStyle:0];
    //[theAlert setIcon:[NSImage imageNamed:@"Error_256px_5.png"]];
    NSLog(@"End run alarm window");
    return [theAlert runModal];
}
-(void)windowShouldClose:(id)sender{
    NSLog(@"manual close welcome form");
    [self.delegate msgFromWelcomeView:@"cancel"];
}
@end
