//
//  welcomeView.h
//  welcomeWinTest
//
//  Created by Weidong Cao on 2019/6/23.
//  Copyright © 2019 Weidong Cao. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol WelcomeViewDelegate<NSObject>
-(void)msgFromWelcomeView:(NSString *)msg;
@end

@interface welcomeView : NSWindowController
{
    IBOutlet NSWindow *window;
    //login
    IBOutlet NSBox *loginBox;
    IBOutlet NSTextField *userTF;
    IBOutlet NSTextField *keyTF;
    IBOutlet NSButton *loginBtn;
    //progress status
    IBOutlet NSTextField *statusTF;
    IBOutlet NSProgressIndicator *statusPI;
}

@property (nonatomic,weak) id<WelcomeViewDelegate> delegate;

@property (nonatomic,assign) BOOL autoLogin;
@property (nonatomic,strong) NSString *userName;
@property (nonatomic,strong) NSString *passWord;

-(void)updateStatus:(NSString *)status progress:(double )value;
-(void)closePage;

-(IBAction)userTFaction:(id)sender;
-(IBAction)loginBtnAction:(id)sender;

@end

