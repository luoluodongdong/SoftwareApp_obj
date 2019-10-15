//
//  exitView.h
//  TT_ICT
//
//  Created by Weidong Cao on 2019/8/13.
//  Copyright © 2019 曹伟东. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol ExitViewDelegate<NSObject>
-(void)msgFromExitView:(NSString *)msg;
@end

@interface ExitView : NSViewController<ExitViewDelegate>
{
    IBOutlet NSButton *okBtn;
    IBOutlet NSButton *cancelBtn;
    IBOutlet NSTextField *msgTF;
    IBOutlet NSTextField *infoTF;
    IBOutlet NSProgressIndicator *progressIn;
}
@property (nonatomic,weak) id<ExitViewDelegate> delegate;

-(void)updateExitStatus:(NSString *)status progressValue:(int )value;
-(void)closeView;

-(IBAction)okBtnAction:(id)sender;
-(IBAction)cancelBtnAction:(id)sender;

@end
