import 'package:flutter/services.dart';
import '../utils/logger.dart';

/// 原生 Bridge 通道名
///
/// 面试讲解点：
/// Channel 名统一管理，避免魔法字符串，原生和 Flutter 两端保持一致。
/// 命名规则：包名 + 功能名，防止和其他插件的 Channel 冲突。
class BridgeChannels {
  static const String nativeBridge = 'com.example.flutter_ecom/native_bridge';
  static const String auth = 'com.example.flutter_ecom/auth';
  static const String payment = 'com.example.flutter_ecom/payment';
  static const String camera = 'com.example.flutter_ecom/camera';
  static const String push = 'com.example.flutter_ecom/push';
}

/// Bridge 方法名常量
class BridgeMethods {
  // 通用
  static const String getAppInfo = 'getAppInfo';
  static const String getDeviceInfo = 'getDeviceInfo';
  static const String toast = 'toast';
  static const String navigateBack = 'navigateBack';

  // 登录
  static const String nativeLogin = 'nativeLogin';
  static const String getToken = 'getToken';
  static const String logout = 'logout';

  // 支付
  static const String aliPay = 'aliPay';
  static const String weChatPay = 'weChatPay';

  // 相机 / 相册
  static const String takePhoto = 'takePhoto';
  static const String pickImage = 'pickImage';

  // 推送
  static const String getPushToken = 'getPushToken';
}

/// 原生 Bridge 管理器（单例）
///
/// 面试讲解点：
/// 1. 统一封装所有 MethodChannel 调用，业务层不直接接触 Channel
/// 2. 统一处理异常、日志、参数校验
/// 3. 用单例模式全局共享，避免重复创建 Channel
///
/// 为什么不用插件的形式？
/// - 项目中的 Bridge 是和业务强相关的，不是通用能力
/// - 统一放在一个文件里便于维护，和原生同学对齐协议也方便
/// - 插件适合通用能力（比如 camera、shared_preferences），业务 Bridge 不需要
class NativeBridge {
  static final NativeBridge _instance = NativeBridge._internal();
  factory NativeBridge() => _instance;
  NativeBridge._internal();

  final MethodChannel _channel = const MethodChannel(BridgeChannels.nativeBridge);

  // ========== 通用方法 ==========

  /// 获取 App 信息（版本号、渠道等）
  Future<Map<String, dynamic>?> getAppInfo() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        BridgeMethods.getAppInfo,
      );
      AppLogger.d('NativeBridge.getAppInfo: $result');
      return result;
    } on PlatformException catch (e, stackTrace) {
      AppLogger.e('NativeBridge.getAppInfo failed: ${e.message}', e, stackTrace);
      return null;
    }
  }

  /// 原生 Toast
  Future<void> showToast(String message) async {
    try {
      await _channel.invokeMethod(BridgeMethods.toast, {'message': message});
    } on PlatformException catch (e, stackTrace) {
      AppLogger.e('NativeBridge.toast failed: ${e.message}', e, stackTrace);
    }
  }

  /// 返回原生页面
  Future<void> navigateBack({Map<String, dynamic>? result}) async {
    try {
      await _channel.invokeMethod(BridgeMethods.navigateBack, result);
    } on PlatformException catch (e, stackTrace) {
      AppLogger.e('NativeBridge.navigateBack failed: ${e.message}', e, stackTrace);
    }
  }

  // ========== 登录相关 ==========

  /// 调用原生登录（如果原生已有登录态，可以直接返回用户信息）
  Future<Map<String, dynamic>?> nativeLogin() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        BridgeMethods.nativeLogin,
      );
      AppLogger.d('NativeBridge.nativeLogin success');
      return result;
    } on PlatformException catch (e, stackTrace) {
      AppLogger.e('NativeBridge.nativeLogin failed: ${e.message}', e, stackTrace);
      return null;
    }
  }

  /// 获取原生保存的 Token
  Future<String?> getToken() async {
    try {
      final token = await _channel.invokeMethod<String>(BridgeMethods.getToken);
      return token;
    } on PlatformException catch (e, stackTrace) {
      AppLogger.e('NativeBridge.getToken failed: ${e.message}', e, stackTrace);
      return null;
    }
  }

  // ========== 支付相关 ==========

  /// 支付宝支付
  /// 返回支付结果状态：success / failure / cancel
  Future<String> aliPay(String orderId, String payInfo) async {
    try {
      final result = await _channel.invokeMethod<String>(
        BridgeMethods.aliPay,
        {'orderId': orderId, 'payInfo': payInfo},
      );
      AppLogger.d('NativeBridge.aliPay result: $result');
      return result ?? 'failure';
    } on PlatformException catch (e, stackTrace) {
      AppLogger.e('NativeBridge.aliPay failed: ${e.message}', e, stackTrace);
      return 'failure';
    }
  }

  // ========== 相机相关 ==========

  /// 拍照，返回图片路径
  Future<String?> takePhoto() async {
    try {
      final path = await _channel.invokeMethod<String>(BridgeMethods.takePhoto);
      return path;
    } on PlatformException catch (e, stackTrace) {
      AppLogger.e('NativeBridge.takePhoto failed: ${e.message}', e, stackTrace);
      return null;
    }
  }
}
