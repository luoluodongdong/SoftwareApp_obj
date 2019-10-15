//
//  MEShelper.m
//  SoftwareApp
//
//  Created by Weidong Cao on 2019/6/19.
//  Copyright © 2019 曹伟东. All rights reserved.
//

#import "MEShelper.h"
#import <Cocoa/Cocoa.h>

#define gh_station_info @"/vault/data_collection/test_station_config/gh_station_info.json"

@implementation MEShelper

-(NSString *)GetGHDValueWithKey:(NSString *)key{
    //NSString *path = @"/vault/data_collection/test_station_config/gh_station_info.json";
    //NSString *path=_gh_file;
    //创建NSFileManager实例
    NSFileManager *fm = [NSFileManager defaultManager];
    //判断文件是否存在
    if([fm fileExistsAtPath:gh_station_info]==NO){
        [self performSelectorOnMainThread:@selector(showAlertViewWarning:) withObject:@"gh_station_info.json file not exists!" waitUntilDone:NO];
        NSLog(@"gh_station_info.json file not exists!");
        return @"";
    }else{
        NSLog(@"file exists");
    }
    //初始化文件路径。
    //NSString* path  = [[NSBundle mainBundle] pathForResource:@"gh_station_info" ofType:@"json"];
    NSLog(@"path:%@",gh_station_info);
    //将文件内容读取到字符串中，注意编码NSUTF8StringEncoding 防止乱码
    NSString* jsonString = [[NSString alloc] initWithContentsOfFile:gh_station_info encoding:NSUTF8StringEncoding error:nil];
    //NSLog(@"jsonString:%@",jsonString);
    //将字符串写到缓冲区。
    NSData* jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    //解析json数据，使用系统方法 JSONObjectWithData:  options: error:
    NSDictionary* dic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableLeaves error:nil];
    //接下来一步一步parse
    NSDictionary* dicResult =[dic objectForKey:@"ghinfo"];
    NSString *value=[dicResult objectForKey:key];
    //NSString *sfcUOP = [dicResult objectForKey:@"SFC_QUERY_UNIT_ON_OFF"];
    //NSString *sfcURL = [dicResult objectForKey:@"SFC_URL"];
    //NSString *stationID = [dicResult objectForKey:@"STATION_ID"];
    //NSString *stationID=[dicResult objectForKey:@"STATION_NUMBER"];
    //NSLog(@"sfcUOP:%@ sfcURL:%@ stationID:%@",sfcUOP,sfcURL,stationID);
    
    return value;
}

-(BOOL)checkUOPwithBody:(NSString *)body sn:(NSString *)strSN
{
    //    strStation = @"ITKS_A02-2FAP-01_3_CON-OQC";
    static BOOL bResult = false;
    //创建信号量,实现同步请求
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    NSURLSession *session=[NSURLSession sharedSession];
    //第一步，创建URL
    //第一步，创建URL
    NSString *strUrl = [self GetGHDValueWithKey:@"SFC_URL"];
    NSLog(@"[MEShelper]url:%@",strUrl);
    //NSString *urlString=@"http://10.37.66.2:8005/LuxShare_QualityTestService.aspx";
    //第二步，创建请求
    NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:strUrl]];
    
    [request setHTTPMethod:@"POST"];
    [request setTimeoutInterval:5.0f];
    //request.HTTPMethod=@"GET";
    //NSString *strData = [NSString stringWithFormat:@"c=QUERY_RECORD&sn=%@&StationID=%@&cmd=QUERY_PANEL", strSN, strStation];
    NSString *strStation=[self GetGHDValueWithKey:@"STATION_ID"];
    //strStation=[strStation componentsSeparatedByString:@"_SMT"][0];
    
    NSString *strBody =[body stringByReplacingOccurrencesOfString:@"{STID}" withString:strStation];
    strBody=[strBody stringByReplacingOccurrencesOfString:@"{SN}" withString:strSN];
    //[NSString stringWithFormat:@"c=QUERY_RECORD&p=unit_process_check&tsid=%@&sn=%@", _mesStationID,strSN];
    [request setHTTPBody:[strBody dataUsingEncoding:NSUTF8StringEncoding]];
    NSLog(@"[MEShelper]Body:%@",strBody);
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
                NSLog(@"[MEShelper]post error；%@",strError);
                [self showAlertViewWarning:@"Connect to network error!"];
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
            NSLog(@"[MEShelper]response:%@",strReceivedData);
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
-(NSString *)POSTwithURL:(NSString *)url Body:(NSString *)body{
    //创建信号量,实现同步请求
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    NSURLSession *session=[NSURLSession sharedSession];
    //第一步，创建URL
    //第一步，创建URL
    NSLog(@"[MEShelper]url:%@",url);
    //NSString *urlString=@"http://10.37.66.2:8005/LuxShare_QualityTestService.aspx";
    //第二步，创建请求
    NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    [request setHTTPMethod:@"POST"];
    [request setTimeoutInterval:5.0f];
    //request.HTTPMethod=@"GET";
    //NSString *strData = [NSString stringWithFormat:@"c=QUERY_RECORD&sn=%@&StationID=%@&cmd=QUERY_PANEL", strSN, strStation];
    [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    NSLog(@"[MEShelper]Body:%@",body);
    //第三步，连接服务器
    NSString static *strReceivedData=@"";
    NSURLSessionDataTask *task=[session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        strReceivedData = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        strReceivedData=[strReceivedData stringByReplacingOccurrencesOfString:@";" withString:@"\r\n"];
        NSString *strError=[NSString stringWithFormat:@"error:%@",error];
        NSLog(@"%@",strError);
        if(![strError isEqual:@"error:(null)"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                //通知主线程更新
                NSLog(@"[MEShelper]post error；%@",strError);
                [self showAlertViewWarning:@"Connect to network error!"];
            });
        }
        //发送 signal
        dispatch_semaphore_signal(semaphore);
    }];
    
    [task resume];
    //等待(阻塞线程)
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    NSLog(@"[MEShelper]response:%@",strReceivedData);
    NSLog(@"task finish");
    
    return strReceivedData;
}
- (void)showAlertViewWarning:(NSString *)strWarning
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    [alert setMessageText:strWarning];
    [alert setAlertStyle:NSAlertStyleWarning];
    [alert runModal];
}

@end
