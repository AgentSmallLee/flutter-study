import 'package:dartz/dartz.dart';

/// 失败抽象类，所有错误类型都继承自它
///
/// 面试讲解点：
/// 使用抽象类表示错误类型，配合 dartz 的 Either 使用，
/// 替代传统的 try-catch 异常抛出，函数返回值明确表示成功/失败两种路径，
/// 调用方必须处理失败情况，避免未捕获的异常。
abstract class Failure {
  const Failure(this.message);

  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure && runtimeType == other.runtimeType && message == other.message;

  @override
  int get hashCode => message.hashCode;
}

/// 服务器错误（5xx）
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

/// 网络连接错误
class NetworkFailure extends Failure {
  const NetworkFailure() : super('网络连接失败，请检查网络设置');
}

/// 未授权错误（401）
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure() : super('登录已过期，请重新登录');
}

/// 业务逻辑错误（code != 200）
class BusinessFailure extends Failure {
  const BusinessFailure(super.message, this.code);

  final int code;
}

/// 缓存错误
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

/// 未知错误
class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}

/// 便捷类型别名，表示「失败或成功」
typedef Result<T> = Either<Failure, T>;
