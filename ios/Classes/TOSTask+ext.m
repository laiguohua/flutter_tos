//
//  TOSTask+ext.m
//  flutter_tos
//
//  Created by 0 on 2024/1/10.
//

#import "TOSTask+ext.h"
#import <objc/runtime.h>

static const void *tos_task_item = @"tos_task_item";

@implementation TOSTask (ext)


- (TosUploadItem *)item{
    NSDictionary *dict = objc_getAssociatedObject(self, &tos_task_item);
    if(dict && [dict isKindOfClass:NSDictionary.class]){
        return [TosUploadItem formMap:dict];
    }
    return nil;
}

- (void)setItem:(TosUploadItem *)item{
    NSDictionary *dict = [item toMap];
    objc_setAssociatedObject(self, &tos_task_item, dict, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end
