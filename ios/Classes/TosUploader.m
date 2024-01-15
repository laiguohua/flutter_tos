//
//  TosUploader.m
//  flutter_tos
//
//  Created by 0 on 2024/1/10.
//

#import "TosUploader.h"
#import "TOSTask+ext.h"
#import <VeTOSiOSSDK/VeTOSiOSSDK.h>

typedef void(^TOSUploadSigleCompleBlock)(TosUploadItem *item);

@interface TosUploader()
@property (nonatomic,strong)TOSClient *client;
@property (nonatomic,strong)NSMutableDictionary <NSString *,TOSCancellationTokenRegistration *>*cancelTokens;
@property (nonatomic,copy)NSDictionary *lastParam;

@end

@implementation TosUploader

- (BOOL)configUploader:(NSDictionary *)param{
    self.lastParam = param;
    // 从STS服务获取的临时访问密钥和安全令牌（AccessKey、SecretKey、SecurityToken）
    NSString *accessKey = param[@"AccessKeyId"]?:@"";
    if([accessKey length] == 0) return NO;
    NSString *secretKey = param[@"SecretAccessKey"]?:@"";
    if([secretKey length] == 0) return NO;
    NSString *securityToken = param[@"SessionToken"]?:@"";
    if([securityToken length] == 0) return NO;
    NSString *endpoint = param[@"Endpoint"]?:@"";
    if([endpoint length] == 0) return NO;
    NSString *region = param[@"Region"]?:@"";
    if([region length] == 0) return NO;
    TOSCredential *credential = [[TOSCredential alloc] initWithAccessKey:accessKey secretKey:secretKey securityToken:securityToken];
    TOSEndpoint *tosEndpoint = [[TOSEndpoint alloc] initWithURLString:endpoint withRegion:region];
    TOSClientConfiguration *config = [[TOSClientConfiguration alloc] initWithEndpoint:tosEndpoint credential:credential];
    TOSClient *client = [[TOSClient alloc] initWithConfiguration:config];
    self.client = client;
    return YES;
}

- (void)uploadFiles:(NSArray<NSDictionary *> *)uploadFiles compleBlock:(TOSUploadCompleBlock)compleBlock{
    if(!self.client && self.lastParam){
        [self configUploader:self.lastParam];
    }
    NSString *bucket = self.lastParam[@"Bucket"]?:@"";
    NSString *host = self.lastParam[@"Host"]?:@"";
    NSInteger expiredTime = [self.lastParam[@"ExpiredTime"] integerValue];
    if(!self.client || bucket.length == 0 || host.length == 0){
        if(compleBlock){
            compleBlock(uploadFiles);
        }
        return;
    }
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    dispatch_group_t _upload_group = dispatch_group_create();
    NSMutableArray <TosUploadItem *>* uploadItems = [NSMutableArray arrayWithCapacity:uploadFiles.count];
    __weak __typeof(self)weakSelf = self;
    for(NSDictionary *file in uploadFiles){
        TosUploadItem *sigleItem = [TosUploadItem formMap:file];
        dispatch_group_enter(_upload_group);
        dispatch_group_async(_upload_group, queue, ^{
            TOSCancellationTokenRegistration *token = [weakSelf _uploadSigleItem:sigleItem compleBlock:^(TosUploadItem *item) {
                __strong __typeof(weakSelf)strongSelf = weakSelf;
                if(item.uuid && [strongSelf.cancelTokens.allKeys containsObject:item.uuid]){
                    [strongSelf.cancelTokens removeObjectForKey:item.uuid];
                }
                [uploadItems addObject:item];
                dispatch_group_leave(_upload_group);
            }];
            if(token && sigleItem.uuid){
                self.cancelTokens[sigleItem.uuid] = token;
            }
        });
    }
    //回调出去
    dispatch_group_notify(_upload_group, dispatch_get_main_queue(), ^{
        NSMutableArray<NSDictionary *> *uploadResultFiles = [NSMutableArray array];
        for(TosUploadItem *aitme in uploadItems){
            NSDictionary *map = [aitme toMap];
            [uploadResultFiles addObject:map];
        }
        if(compleBlock){
            compleBlock(uploadResultFiles);
        }
    });
}

- (TOSCancellationTokenRegistration *)_uploadSigleItem:(TosUploadItem *)sigleItem  compleBlock:(TOSUploadSigleCompleBlock)compleBlock{
    NSString *bucket = self.lastParam[@"Bucket"]?:@"";
    NSString *host = self.lastParam[@"Host"]?:@"";
    host = [host stringByReplacingOccurrencesOfString:@"\\" withString:@""];
    NSInteger expiredTime = [self.lastParam[@"ExpiredTime"] integerValue];
    
    TOSPutObjectFromFileInput *put = [[TOSPutObjectFromFileInput alloc] init];
    put.tosBucket = bucket;
    NSString *time = [@([[NSDate date] timeIntervalSince1970]) stringValue];
    time = [time stringByReplacingOccurrencesOfString:@"." withString:@""];
    int r = arc4random() % 1000000;
    NSString *filePath = [[sigleItem.fileStr lastPathComponent] stringByDeletingPathExtension];
    filePath = [filePath stringByReplacingOccurrencesOfString:@"." withString:@""];
    filePath = [filePath stringByReplacingOccurrencesOfString:@":" withString:@""];
    NSString *tosKey = [NSString stringWithFormat:@"%@_%d_%@.%@",time,r,filePath,[sigleItem.fileStr pathExtension]];
//    NSLog(@"=====路径为%@",tosKey);
    put.tosKey = tosKey;
    put.tosFilePath = sigleItem.fileStr;
    TOSTask *task = [self.client putObjectFromFile:put];
    task.item = sigleItem;
    TOSCancellationToken *cacelToken = [TOSCancellationToken new];
    //取消请求时执行到这里
    TOSCancellationTokenRegistration *tokenRegist = [cacelToken registerCancellationObserverWithBlock:^{
//        NSLog(@"执行了取消上传");
        TosUploadItem *aitem = task.item;
        if(!aitem.isCompleted){
            aitem.isCompleted = YES;
            aitem.code = @(-2);
            aitem.msg = @"取消上传";
            task.item = aitem;
            dispatch_async(dispatch_get_main_queue(), ^{
                if(compleBlock){
                    compleBlock(aitem);
                }
            });
        }
    }];
    //执行上传
    [task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
        TosUploadItem *aitem = t.item;
        if(aitem.isCompleted) return nil;
        if (!t.error) {
//                NSLog(@"Create bucket success.");
            aitem.code = @(0);
            aitem.msg = @"";
            aitem.isCompleted = YES;
            NSString *url = [NSString stringWithFormat:@"%@%@%@",host,[host hasSuffix:@"/"]?@"":@"/",tosKey];
//            NSLog(@"url为====%@",url);
            aitem.downloadUrl = url;
        } else {
            NSLog(@"Create bucket failed, error: %@.", t.error);
            aitem.code = @(t.error.code);
            aitem.msg = [t.error localizedDescription];
            aitem.isCompleted = YES;
        }
        t.item = aitem;
//        NSLog(@"单个回调====");
        dispatch_async(dispatch_get_main_queue(), ^{
            if(compleBlock){
                compleBlock(aitem);
            }
        });
            return nil;
    } cancellationToken:cacelToken];
    return tokenRegist;
}

- (void)cancelUploadWithIds:(NSArray <NSString *>*)ids{
    if([self.cancelTokens count] == 0){
        return;
    }
    if([ids count] == 0) return;
    for(NSString *uuid in ids){
        if([self.cancelTokens.allKeys containsObject:uuid]){
            TOSCancellationTokenRegistration *token = self.cancelTokens[uuid];
            [token dispose];
            [self.cancelTokens removeObjectForKey:uuid];
        }
    }
}

- (void)cancelAllUpload{
    if([self.cancelTokens count] == 0){
        return;
    }
    for(TOSCancellationTokenRegistration *token in self.cancelTokens){
        [token dispose];
    }
    [self.cancelTokens removeAllObjects];
}

#pragma mark - lazyload
- (NSMutableDictionary<NSString *,TOSCancellationTokenRegistration *> *)cancelTokens{
    if(!_cancelTokens){
        _cancelTokens = [NSMutableDictionary dictionary];
    }
    return _cancelTokens;
}

@end
