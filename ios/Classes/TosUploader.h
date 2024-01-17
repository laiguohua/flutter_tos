//
//  TosUploader.h
//  flutter_tos
//
//  Created by 0 on 2024/1/10.
//

#import <Foundation/Foundation.h>

typedef void(^TOSUploadCompleBlock)(NSArray <NSDictionary *>*uploadFiles);


@interface TosUploader : NSObject

- (BOOL)configUploader:(NSDictionary *)param;

- (void)uploadFiles:(NSArray <NSDictionary *>*)uploadFiles compleBlock:(TOSUploadCompleBlock)compleBlock;

- (void)cancelUploadWithIds:(NSArray <NSString *>*)ids;

- (void)cancelAllUpload;

/// 计算大文件MD5
- (NSString*)getBigfileMD5:(NSString*)path;

@end


