//
//  TosUploadItem.m
//  flutter_tos
//
//  Created by 0 on 2024/1/10.
//

#import "TosUploadItem.h"

@implementation TosUploadItem
+ (TosUploadItem *)formMap:(NSDictionary *)map{
    TosUploadItem *item = [TosUploadItem new];
    if([map.allKeys containsObject:@"uuid"]){
        item.uuid = map[@"uuid"];
    }
    if([map.allKeys containsObject:@"fileStr"]){
        item.fileStr = map[@"fileStr"];
    }
    if([map.allKeys containsObject:@"ext"]){
        item.ext = map[@"ext"];
    }
    if([map.allKeys containsObject:@"downloadUrl"]){
        item.downloadUrl = map[@"downloadUrl"];
    }
    if([map.allKeys containsObject:@"isCompleted"]){
        item.isCompleted = [map[@"isCompleted"] boolValue];
    }
    if([map.allKeys containsObject:@"msg"]){
        item.msg = map[@"msg"];
    }
    if([map.allKeys containsObject:@"code"]){
        item.code = map[@"code"];
    }
    return item;
}
- (NSDictionary *)toMap{
    NSMutableDictionary *map = @{}.mutableCopy;
    if(self.uuid){
        map[@"uuid"] = self.uuid;
    }
    if(self.fileStr){
        map[@"fileStr"] = self.fileStr;
    }
    if(self.ext){
        map[@"ext"] = self.ext;
    }
    if(self.downloadUrl){
        map[@"downloadUrl"] = self.downloadUrl;
    }
    map[@"msg"] = self.msg?:@"";
    map[@"code"] = self.code?:@(-1);
    map[@"isCompleted"] = @(self.isCompleted);
    return map;
}
@end
