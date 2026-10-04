import 'package:dio/dio.dart';
import 'failures.dart';
import '../utils/logger.dart';

/// 全局错误处理器
///
/// 负责将各种类型的异常统一转换为 [Failure]，
/// 供 Repository 层向上返回。
class ErrorHandler {
  ErrorHandler._();

  /// 将 [DioException] 转换为 [Failure]
  static Failure handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkFailure();
      case DioExceptionType.badResponse:
        return _handleResponseError(error.response);
      case DioExceptionType.unknown:
        if (error.error != null && error.error.toString().contains('SocketException')) {
          return const NetworkFailure();
        }
        return UnknownFailure(error.message ?? '未知错误');
      case DioExceptionType.cancel:
        return const UnknownFailure('请求已取消');
      case DioExceptionType.badCertificate:
        return const UnknownFailure('证书验证失败');
      case DioExceptionType.connectionError:
        return const NetworkFailure();
      case DioExceptionType.transformTimeout:
        return const NetworkFailure();
    }
  }

  /// 处理 HTTP 错误响应
  static Failure _handleResponseError(Response? response) {
    final statusCode = response?.statusCode ?? -1;
    final data = response?.data;

    // 尝试从响应体中解析错误消息
    String message = '请求失败';
    if (data is Map<String, dynamic> && data['message'] != null) {
      message = data['message']?.toString() ?? message;
    }

    AppLogger.e('HTTP Error $statusCode: $message');

    switch (statusCode) {
      case 401:
        return const UnauthorizedFailure();
      case 403:
        return ServerFailure(message);
      case 404:
        return const ServerFailure('资源不存在');
      case 500:
      case 501:
      case 502:
      case 503:
      case 504:
        return ServerFailure('服务器异常，请稍后再试');
      default:
        return BusinessFailure(message, statusCode);
    }
  }

  /// 捕获通用异常并转换为 Failure
  static Failure handleError(dynamic error) {
    AppLogger.e('Unknown error: $error');
    if (error is DioException) {
      return handleDioError(error);
    }
    return UnknownFailure(error.toString());
  }
}
