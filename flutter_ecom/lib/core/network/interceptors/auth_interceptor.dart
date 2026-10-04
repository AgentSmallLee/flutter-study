import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants/storage_keys.dart';
import '../../utils/logger.dart';

/// Token 认证拦截器
///
/// 在请求头中自动添加 Authorization: Bearer <token>
///
/// 面试讲解点（混合开发场景）：
/// 在 Flutter Module 嵌入原生 App 的场景下，登录态通常由原生维护，
/// Flutter 侧通过 MethodChannel 从原生获取 Token，而不是自己存。
/// 这里用「本地缓存 + 原生兜底」的策略：
/// 1. 先读 SharedPreferences（本地缓存，减少 Channel 调用次数）
/// 2. 本地没有时，从 NativeBridge 获取原生 Token（同步阻塞，因为 Dio 拦截器是同步的）
/// 3. 实际项目中一般是登录时原生主动把 Token 传给 Flutter，Flutter 缓存起来用
///
/// 当收到 401 时可以在这里统一处理登出逻辑（如跳转到登录页）。
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._sharedPreferences);

  final SharedPreferences _sharedPreferences;

  /// 是否使用原生 Token（混合开发模式下从原生获取登录态）
  /// 面试讲解点：通过配置切换独立运行 / 嵌入原生两种模式
  static const bool useNativeToken = false;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _sharedPreferences.getString(StorageKeys.userToken);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
      AppLogger.d('Add auth token to request: ${options.path}');
    }
    // 混合开发模式下，如果本地没有 token，可以从原生获取
    // 注意：Dio 拦截器 onRequest 是同步的，实际项目中建议用 QueuedInterceptor
    // 或者在 App 启动时就把原生的 token 同步到本地
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // 401 未授权的情况可以在这里做全局处理，比如清除 token 并跳转登录
    if (err.response?.statusCode == 401) {
      AppLogger.w('Unauthorized request: ${err.requestOptions.path}');
      // 实际项目中这里会触发全局登出事件（比如通过 AuthBloc）
    }
    super.onError(err, handler);
  }
}
