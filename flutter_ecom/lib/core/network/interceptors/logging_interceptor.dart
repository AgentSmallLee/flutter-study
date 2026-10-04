import 'package:dio/dio.dart';
import '../../utils/logger.dart';

/// 日志拦截器
///
/// 打印请求和响应的详细信息，方便调试。
/// 生产环境建议移除或调整日志级别。
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    AppLogger.d(
      '┌───────────────────────────────────────────────────',
    );
    AppLogger.d('│ 🚀 Request: ${options.method} ${options.uri}');
    AppLogger.d('│ Headers: ${options.headers}');
    if (options.data != null) {
      AppLogger.d('│ Body: ${options.data}');
    }
    AppLogger.d(
      '└───────────────────────────────────────────────────',
    );
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    AppLogger.i(
      '┌───────────────────────────────────────────────────',
    );
    AppLogger.i('│ ✅ Response: ${response.statusCode} ${response.requestOptions.uri}');
    AppLogger.i('│ Data: ${response.data.toString().substring(
          0,
          response.data.toString().length > 500
              ? 500
              : response.data.toString().length,
        )}${response.data.toString().length > 500 ? '...' : ''}');
    AppLogger.i(
      '└───────────────────────────────────────────────────',
    );
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppLogger.e(
      '┌───────────────────────────────────────────────────',
    );
    AppLogger.e('│ ❌ Error: ${err.requestOptions.method} ${err.requestOptions.uri}');
    AppLogger.e('│ Type: ${err.type}');
    AppLogger.e('│ Message: ${err.message}');
    if (err.response != null) {
      AppLogger.e('│ Status: ${err.response?.statusCode}');
      AppLogger.e('│ Data: ${err.response?.data}');
    }
    AppLogger.e(
      '└───────────────────────────────────────────────────',
    );
    super.onError(err, handler);
  }
}
