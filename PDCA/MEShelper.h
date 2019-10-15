//
//  MEShelper.h
//  SoftwareApp
//
//  Created by Weidong Cao on 2019/6/19.
//  Copyright © 2019 曹伟东. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MEShelper : NSObject

/*!
 *get the value from gh_station_info.json pass key
 *key:exp:@"STATION_ID"
 *return:the value of the key
 */
-(NSString *)GetGHDValueWithKey:(NSString *)key;

/*!
 *check unit out of process with PDCA server
 *body:@"c=QUERY_RECORD&sn={SN}&StationID={STID}&cmd=QUERY_PANEL"
 *sn:the SN of DUT
 *return: YES-SN is OK // NO-SN is out of process
 */
-(BOOL)checkUOPwithBody:(NSString *)body sn:(NSString *)strSN;

/*!
 *post the SFC with url/body
 *return: the response of SFC
 *
 */
-(NSString *)POSTwithURL:(NSString *)url Body:(NSString *)body;

@end

NS_ASSUME_NONNULL_END
