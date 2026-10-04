import 'package:logger/logger.dart';

/// 全局日志工具
///
/// 封装 logger 包，统一日志输出格式。
///
/// 面试讲解点：
/// 生产环境可以把 level 设置 Level.none 来关闭日志，
/// 避免敏感信息泄露，同时也减少性能开销。
class AppLogger {
  AppLogger._();

  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: false,
    ),
  );

  /// Verbose 日志（最详细）
  static void v(dynamic message) => _logger.t(message);

  /// Debug 日志
  static void d(dynamic message) => _logger.d(message);

  /// Info 日志
  static void i(dynamic message) => _logger.i(message);

  /// Warning 日志
  static void w(dynamic message) => _logger.w(message);

  /// Error 日志
  static void e(dynamic message, [dynamic error, StackTrace? stackTrace]) =>
      _logger.e(message, error: error, stackTrace: stackTrace);
}
