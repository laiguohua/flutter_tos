import 'flutter_tos_platform_interface.dart';

class FlutterTos {
  //获取设备版本
  Future<String?> getPlatformVersion() {
    return FlutterTosPlatform.instance.getPlatformVersion();
  }

  //配置上传信息
  Future<bool?> configClient(Map param) async {
    return FlutterTosPlatform.instance.configClient(param);
  }

  /**
   * Map 字段说明
   //上传的唯一标识
@property(nonatomic,copy)NSString *uuid;
//上传的文件路径
@property(nonatomic,copy)NSString *fileStr;
//扩展数据
@property(nonatomic)id ext;
//下载链接,完成后这个有值
@property(nonatomic,copy)NSString *downloadUrl;
//是否完成
@property(nonatomic,assign)BOOL isCompleted;
//错误的话这里放错误原因,请求完成有值
@property(nonatomic,copy)NSString *msg;
//code 请求完成有值
@property(nonatomic,copy)NSNumber *code;
   */
  //上传文件
  Future<List?> uploadFiles(List<Map> files) async {
    return FlutterTosPlatform.instance.uploadFiles(files);
  }

  //通过唯一id去取消上传
  Future<void> cancelUpload(List<String> ids) {
    return FlutterTosPlatform.instance.cancelUpload(ids);
  }

  //取消所有的上传
  Future<void> cancelAllUpload() {
    return FlutterTosPlatform.instance.cancelAllUpload();
  }
}
