import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_tos_platform_interface.dart';

/// An implementation of [FlutterTosPlatform] that uses method channels.
class MethodChannelFlutterTos extends FlutterTosPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('com.jx.flutter_tos.channel');

  @override
  Future<String?> getPlatformVersion() {
    return methodChannel.invokeMethod<String>('getPlatformVersion');
  }

  @override
  Future<bool?> configClient(Map param) async {
    return methodChannel.invokeMethod<bool>('configClient', param);
  }

  @override
  Future<List?> uploadFiles(List<Map> files) async {
    Map? map =
        await methodChannel.invokeMethod<Map>('uploadFiles', {"files": files});
    if (map != null) {
      return map["files"];
    }
    return null;
  }

  @override
  Future<void> cancelUpload(List<String> ids) {
    return methodChannel.invokeMethod('cancelUpload', {"ids": ids});
  }

  @override
  Future<void> cancelAllUpload() {
    return methodChannel.invokeMethod('cancelAllUpload');
  }
}
