import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/logging_interceptor.dart';

/// Dio 客户端封装
///
/// 统一配置 Dio 实例，包括基础 URL、超时时间、拦截器链等。
///
/// 面试讲解点：
/// 拦截器的执行顺序：AuthInterceptor → LoggingInterceptor → ErrorInterceptor
/// - 请求阶段：按添加顺序执行（onRequest）
/// - 响应/错误阶段：按添加的逆序执行（onResponse / onError）
/// 因此把 Auth 放最前面，确保 Logging 能记录到加了 token 的请求。
class DioClient {
  DioClient({
    required AuthInterceptor authInterceptor,
    required LoggingInterceptor loggingInterceptor,
    required ErrorInterceptor errorInterceptor,
    HttpClientAdapter? httpClientAdapter,
  }) : _dio = Dio(
          BaseOptions(
            baseUrl: ApiConstants.baseUrl,
            connectTimeout: const Duration(milliseconds: ApiConstants.connectTimeout),
            receiveTimeout: const Duration(milliseconds: ApiConstants.receiveTimeout),
            sendTimeout: const Duration(milliseconds: ApiConstants.sendTimeout),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ) {
    // 设置自定义 Adapter（Mock 模式下会替换为 MockAdapter）
    if (httpClientAdapter != null) {
      _dio.httpClientAdapter = httpClientAdapter;
    }

    // 添加拦截器（注意顺序：Auth → Logging → Error）
    _dio.interceptors.addAll([
      authInterceptor,
      loggingInterceptor,
      errorInterceptor,
    ]);
  }

  final Dio _dio;

  /// 获取原始 Dio 实例（特殊情况下使用）
  Dio get dio => _dio;

  /// GET 请求
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// POST 请求
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// PUT 请求
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// DELETE 请求
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }
}
