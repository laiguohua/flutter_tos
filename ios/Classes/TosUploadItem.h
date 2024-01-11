//
//  TosUploadItem.h
//  flutter_tos
//
//  Created by 0 on 2024/1/10.
//

#import <Foundation/Foundation.h>

@interface TosUploadItem : NSObject
//上传的唯一标识
@property(nonatomic,copy)NSString *uuid;
//上传的文件路径
@property(nonatomic,copy)NSString *fileStr;
//扩展数据
@property(nonatomic)id ext;
//下载链接,完成后这个有值
@property(nonatomic,copy)NSString *downloadUrl;
//是否完成
@property(nonatomic,assign)BOOL isCompleted;
//错误的话这里放错误原因,请求完成有值
@property(nonatomic,copy)NSString *msg;
//code 请求完成有值
@property(nonatomic,copy)NSNumber *code;


+ (TosUploadItem *)formMap:(NSDictionary *)map;
- (NSDictionary *)toMap;
@end

