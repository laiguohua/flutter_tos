import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_tos_method_channel.dart';

abstract class FlutterTosPlatform extends PlatformInterface {
  /// Constructs a FlutterTosPlatform.
  FlutterTosPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterTosPlatform _instance = MethodChannelFlutterTos();

  /// The default instance of [FlutterTosPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterTos].
  static FlutterTosPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterTosPlatform] when
  /// they register themselves.
  static set instance(FlutterTosPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('getPlatformVersion() has not been implemented.');
  }

  Future<bool?> configClient(Map param) {
    throw UnimplementedError('configClient() has not been implemented.');
  }

  Future<List?> uploadFiles(List<Map> files) {
    throw UnimplementedError('uploadFiles() has not been implemented.');
  }

  Future<void> cancelUpload(List<String> ids) {
    throw UnimplementedError('cancelUpload() has not been implemented.');
  }

  Future<void> cancelAllUpload() {
    throw UnimplementedError('cancelAllUpload() has not been implemented.');
  }

  //获取文件的MD5值
  Future<String> getFileMd5({required String file}) {
    throw UnimplementedError('cancelAllUpload() has not been implemented.');
  }
}
