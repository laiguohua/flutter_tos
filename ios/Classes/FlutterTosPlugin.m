#import "FlutterTosPlugin.h"
#import "FlutterTosMethodHandler.h"

@implementation FlutterTosPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
     [FlutterTosMethodHandler registerWithRegistrar:registrar];
}

@end
