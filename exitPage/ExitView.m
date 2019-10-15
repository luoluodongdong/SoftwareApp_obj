//
//  exitView.m
//  TT_ICT
//
//  Created by Weidong Cao on 2019/8/13.
//  Copyright © 2019 曹伟东. All rights reserved.
//

#import "ExitView.h"

@implementation ExitView
{
    
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    [self setTitle:@"Exit"];
    [infoTF setHidden:YES];
    [progressIn setHidden:YES];
    [okBtn setHighlighted:NO];
    [cancelBtn setHighlighted:YES];
}

-(void)viewWillDisappear{

}

-(void)updateExitStatus:(NSString *)status progressValue:(int )value{
    if(value >100.0) value=100.0;
    dispatch_async(dispatch_get_main_queue(), ^{
        //通知主线程更新
        [self->infoTF setStringValue:status];
        [self->progressIn setDoubleValue:value];
    });
}
-(void)closeView{
    dispatch_async(dispatch_get_main_queue(), ^{
        //通知主线程更新
        [self dismissController:self];
    });
    
}
-(IBAction)okBtnAction:(id)sender{
    [msgTF setHidden:YES];
    [infoTF setHidden:NO];
    [progressIn setHidden:NO];
    [cancelBtn setHidden:YES];
    [okBtn setHidden:YES];
    [self.delegate msgFromExitView:@"EXIT"];
}
-(IBAction)cancelBtnAction:(id)sender{
    [self.delegate msgFromExitView:@"CANCEL"];
    
}

@end
