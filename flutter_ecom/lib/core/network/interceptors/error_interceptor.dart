import 'package:dio/dio.dart';
import '../../utils/logger.dart';

/// 错误拦截器
///
/// 统一处理 Dio 错误，将原始错误包装后再向上抛出。
/// 主要用于统一日志记录和错误埋点。
///
/// 注意：错误到 Failure 的转换在 ErrorHandler 中完成，
/// 拦截器只负责记录和透传。
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppLogger.e(
      'Network error intercepted: ${err.type} - ${err.message}',
      err,
      err.stackTrace,
    );
    super.onError(err, handler);
  }
}
