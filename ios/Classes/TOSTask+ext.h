//
//  TOSTask+ext.h
//  flutter_tos
//
//  Created by 0 on 2024/1/10.
//

#import <Foundation/Foundation.h>
#import <VeTOSiOSSDK/VeTOSiOSSDK.h>
#import "TosUploadItem.h"


@interface TOSTask (ext)

@property(nonatomic,strong)TosUploadItem *item;

@end

