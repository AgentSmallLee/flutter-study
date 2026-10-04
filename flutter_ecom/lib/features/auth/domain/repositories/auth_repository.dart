import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';

/// 认证 Repository 接口
abstract class AuthRepository {
  /// 登录
  Future<Result<UserEntity>> login({
    required String phone,
    required String password,
  });

  /// 注册
  Future<Result<UserEntity>> register({
    required String phone,
    required String code,
    required String password,
  });

  /// 登出
  Future<void> logout();

  /// 获取当前登录用户
  Future<UserEntity?> getCurrentUser();

  /// 是否登录
  Future<bool> isLoggedIn();
}
