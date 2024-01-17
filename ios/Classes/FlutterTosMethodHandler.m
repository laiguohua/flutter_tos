//
//  FlutterTosMethodHandler.m
//  flutter_tos
//
//  Created by 0 on 2024/1/10.
//

#import "FlutterTosMethodHandler.h"
#import "TosUploader.h"

@interface FlutterTosMethodHandler()
@property (nonatomic,strong)FlutterMethodChannel *currentChannel;
@property (nonatomic,strong)TosUploader *uploader;
@end

@implementation FlutterTosMethodHandler

static FlutterTosMethodHandler *instance = nil;

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[FlutterTosMethodHandler alloc] init];
    });
    return instance;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar{
    FlutterMethodChannel* channel = [FlutterMethodChannel
        methodChannelWithName:@"com.jx.flutter_tos.channel"
              binaryMessenger:[registrar messenger]];
    [FlutterTosMethodHandler.sharedInstance configMethodChannel:channel];
  [registrar addMethodCallDelegate:FlutterTosMethodHandler.sharedInstance channel:channel];
}

- (void)configMethodChannel:(FlutterMethodChannel *)channel{
    self.currentChannel = channel;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if([@"getPlatformVersion" isEqualToString:call.method]){
        result([UIDevice currentDevice].systemVersion);
    }else if ([@"configClient" isEqualToString:call.method]) {
        result(@([self.uploader configUploader:call.arguments]));
    }else if([@"uploadFiles" isEqualToString:call.method]){
        NSArray <NSDictionary *>* files = call.arguments[@"files"];
        if(![files isKindOfClass:NSArray.class]){
            if(result){
                result(call.arguments);
            }
            return;
        }
        [self.uploader uploadFiles:files compleBlock:^(NSArray<NSDictionary *> *uploadFiles) {
            if(result){
                result(@{@"files":uploadFiles});
            }
        }];
    }else if ([@"cancelUpload" isEqualToString:call.method]) {
        NSArray <NSString *> *cancelIds = call.arguments[@"ids"]?:@[];
        [self.uploader cancelUploadWithIds:cancelIds];
        if(result){
            result(@(YES));
        }
    }else if ([@"cancelAllUpload" isEqualToString:call.method]) {
        [self.uploader cancelAllUpload];
        if(result){
            result(@(YES));
        }
    }else if ([@"getFileMd5" isEqualToString:call.method]) {
        //获取文件的MD5值
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSString *md5 = @"";
            @try {
                NSString *file = call.arguments[@"file"];
                md5 = [self.uploader getBigfileMD5:file];
            } @catch (NSException *exception) {
                
            } @finally {
                if(result){
                    result(md5);
                }
            }
        });
        
    }   else {
        result(FlutterMethodNotImplemented);
    }
}


#pragma mark - lazyload
- (TosUploader *)uploader{
    if(!_uploader){
        _uploader = [TosUploader new];
    }
    return _uploader;
}

@end
