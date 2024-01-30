//
//  TosUploader.m
//  flutter_tos
//
//  Created by 0 on 2024/1/10.
//

#import "TosUploader.h"
#import "TOSTask+ext.h"
#import <VeTOSiOSSDK/VeTOSiOSSDK.h>
#import <CommonCrypto/CommonDigest.h>

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
    NSString *dirStr = self.lastParam[@"_dir_"]?:@"";
    host = [host stringByReplacingOccurrencesOfString:@"\\" withString:@""];
    NSInteger expiredTime = [self.lastParam[@"ExpiredTime"] integerValue];
    NSString *time = [@([[NSDate date] timeIntervalSince1970]) stringValue];
    time = [time stringByReplacingOccurrencesOfString:@"." withString:@""];
    int r = arc4random() % 1000000;
    NSString *filePath = [[sigleItem.fileStr lastPathComponent] stringByDeletingPathExtension];
    filePath = [filePath stringByReplacingOccurrencesOfString:@"." withString:@""];
    filePath = [filePath stringByReplacingOccurrencesOfString:@":" withString:@""];
    NSString *tosKey = [NSString stringWithFormat:@"%@_%d_%@.%@",time,r,filePath,[sigleItem.fileStr pathExtension]];
    //有文件夹的话要加上
    if(dirStr.length > 0){
        tosKey = [NSString stringWithFormat:@"%@%@%@",dirStr, ([dirStr hasSuffix:@"/"] || [tosKey hasPrefix:@"/"])?@"":@"/",tosKey];
    }
    //计算文件的MD5值作为文件名
    NSString *md5;
    @try {
        md5 = [self getBigfileMD5:sigleItem.fileStr];
//        NSLog(@"计算出来的MD5值为===%@",md5);
    } @catch (NSException *exception) {
        
    } @finally {
        
    }
    __block BOOL fileExsit = NO;
    //如果计算出来了MD5值，则用MD5值作为tosKey
    if(md5 && md5.length > 1){
        tosKey = md5;
        //有文件夹的话要加上
        if(dirStr.length > 0){
            tosKey = [NSString stringWithFormat:@"%@%@%@",dirStr,([dirStr hasSuffix:@"/"] || [md5 hasPrefix:@"/"])?@"":@"/",md5];
        }
        //获取元数据，查看该对象存不存在，存在的话就不用上传了
        tosKey = [tosKey stringByAppendingPathExtension:[sigleItem.fileStr pathExtension]];
        
        TOSHeadObjectInput *headInput = [TOSHeadObjectInput new];
        headInput.tosBucket = bucket;
        headInput.tosKey = tosKey;
        TOSTask *task = [self.client headObject:headInput];
        [[task continueWithBlock:^id _Nullable(TOSTask * _Nonnull t) {
            if([t.result isKindOfClass:TOSHeadObjectOutput.class]){
                TOSHeadObjectOutput *headOutput = t.result;
                if(headOutput.tosStatusCode == 200){
                    fileExsit = YES;
//                    NSLog(@"文件存在");
                    sigleItem.code = @(0);
                    sigleItem.msg = @"";
                    sigleItem.isCompleted = YES;
                    NSString *url = [NSString stringWithFormat:@"%@%@%@",host,([host hasSuffix:@"/"] || [tosKey hasPrefix:@"/"])?@"":@"/",tosKey];
//                    NSLog(@"url为====%@",url);
                    sigleItem.downloadUrl = url;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if(compleBlock){
                            compleBlock(sigleItem);
                        }
                    });
                }else{
                    fileExsit = NO;
                }
            }else{
                fileExsit = NO;
            }
            return nil;
        }] waitUntilFinished];
    }
    //文件如果不存在，则上传
    if(!fileExsit){
//        NSLog(@"文件不存在,tosKey为===%@",tosKey);
        TOSPutObjectFromFileInput *put = [[TOSPutObjectFromFileInput alloc] init];
        put.tosBucket = bucket;
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
                NSString *url = [NSString stringWithFormat:@"%@%@%@",host,([host hasSuffix:@"/"] || [tosKey hasPrefix:@"/"])?@"":@"/",tosKey];
                //            NSLog(@"url为====%@",url);
                aitem.downloadUrl = url;
            } else {
//                NSLog(@"Create bucket failed, error: %@.", t.error);
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
    return nil;
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

#pragma mark - 计算文件的MD5值
//首先声明一个宏定义
#define FileHashDefaultChunkSizeForReadingData 1024*8
CFStringRef FileMD5HashCreateWithPath(CFStringRef filePath,
                                      size_t chunkSizeForReadingData) {
    
    // Declare needed variables
    CFStringRef result = NULL;
    CFReadStreamRef readStream = NULL;
    
    // Get the file URL
    CFURLRef fileURL =
    CFURLCreateWithFileSystemPath(kCFAllocatorDefault,
                                  (CFStringRef)filePath,
                                  kCFURLPOSIXPathStyle,
                                  (Boolean)false);
    if (!fileURL) goto done;
    
    // Create and open the read stream
    readStream = CFReadStreamCreateWithFile(kCFAllocatorDefault,
                                            (CFURLRef)fileURL);
    if (!readStream) goto done;
    bool didSucceed = (bool)CFReadStreamOpen(readStream);
    if (!didSucceed) goto done;
    
    // Initialize the hash object
    CC_MD5_CTX hashObject;
    CC_MD5_Init(&hashObject);
    
    // Make sure chunkSizeForReadingData is valid
    if (!chunkSizeForReadingData) {
        chunkSizeForReadingData = FileHashDefaultChunkSizeForReadingData;
    }
    
    // Feed the data to the hash object
    bool hasMoreData = true;
    while (hasMoreData) {
        uint8_t buffer[chunkSizeForReadingData];
        CFIndex readBytesCount = CFReadStreamRead(readStream,
                                                  (UInt8 *)buffer,
                                                  (CFIndex)sizeof(buffer));
        if (readBytesCount == -1) break;
        if (readBytesCount == 0) {
            hasMoreData = false;
            continue;
        }
        CC_MD5_Update(&hashObject,(const void *)buffer,(CC_LONG)readBytesCount);
    }
    
    // Check if the read operation succeeded
    didSucceed = !hasMoreData;
    
    // Compute the hash digest
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5_Final(digest, &hashObject);
    
    // Abort if the read operation failed
    if (!didSucceed) goto done;
    
    // Compute the string result
    char hash[2 * sizeof(digest) + 1];
    for (size_t i = 0; i < sizeof(digest); ++i) {
        snprintf(hash + (2 * i), 3, "%02x", (int)(digest[i]));
    }
    result = CFStringCreateWithCString(kCFAllocatorDefault,
                                       (const char *)hash,
                                       kCFStringEncodingUTF8);
    
done:
    
    if (readStream) {
        CFReadStreamClose(readStream);
        CFRelease(readStream);
    }
    if (fileURL) {
        CFRelease(fileURL);
    }
    return result;
}
/// 计算大文件MD5
- (NSString*)getBigfileMD5:(NSString*)path
{
    NSFileManager *handle = [NSFileManager defaultManager];
    // 若是文件不存在
    if(![handle fileExistsAtPath:path isDirectory:nil]) {
        return @"";
    }
    return (__bridge_transfer NSString *)FileMD5HashCreateWithPath((__bridge CFStringRef)path, FileHashDefaultChunkSizeForReadingData);
}

@end
