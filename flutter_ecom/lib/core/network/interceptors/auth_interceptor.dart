import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../bridge/native_bridge.dart';
import '../../constants/storage_keys.dart';
import '../../utils/logger.dart';

/// Token 认证拦截器
///
/// 在请求头中自动添加 Authorization: Bearer <token>
///
/// 面试讲解点（混合开发场景）：
/// 在 Flutter Module 嵌入原生 App 的场景下，登录态由原生维护，
/// Flutter 侧采用「本地缓存 + 启动时同步」的策略：
/// 1. App 启动时通过 NativeBridge 从原生同步最新 Token 到本地
/// 2. 拦截器直接读本地 SharedPreferences，性能最好
/// 3. 收到 401 时，通知原生处理登出逻辑，并清除本地缓存
///
/// 为什么不在拦截器里实时调用 Channel 取 token？
/// - Dio 的 onRequest 拦截器是同步的，不能直接 await Channel 调用
/// - 每次请求都走 Channel 有性能开销
/// - 启动时同步一次 + 登录登出时同步，足够保证一致性
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._sharedPreferences);

  final SharedPreferences _sharedPreferences;

  /// 是否使用原生登录态（混合开发模式）
  /// 面试讲解点：通过配置切换独立运行 / 嵌入原生两种模式
  static const bool useNativeToken = true;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _sharedPreferences.getString(StorageKeys.userToken);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
      AppLogger.d('Add auth token to request: ${options.path}');
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // 401 未授权：混合开发模式下通知原生处理登出
    if (err.response?.statusCode == 401) {
      AppLogger.w('Unauthorized request: ${err.requestOptions.path}');
      if (useNativeToken) {
        // 通知原生处理登出（跳登录页、清除原生 token 等）
        // 异步调用，不阻塞错误向上传递
        NativeBridge().logout().catchError((_) {});
      }
      // 清除本地 token
      _sharedPreferences.remove(StorageKeys.userToken);
    }
    super.onError(err, handler);
  }
}
