import 'dart:async';
import 'package:dartz/dartz.dart';

import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';

/// 认证 Repository 实现
///
/// 面试讲解点：
/// Repository 模式在这里体现了「数据汇集层」的价值：
/// - login：先调用远程接口，成功后把 token 和用户信息存到本地
/// - getCurrentUser：先从本地读，本地没有再从网络获取
/// - logout：清除本地数据
///
/// 上层（Bloc / UseCase）不需要知道数据从哪来，只需调用 Repository 的方法。
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remoteDataSource, this._localDataSource);

  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  @override
  Future<Result<UserEntity>> login({
    required String phone,
    required String password,
  }) async {
    try {
      final userModel = await _remoteDataSource.login(
        phone: phone,
        password: password,
      );
      // 登录成功，保存到本地
      await _localDataSource.saveToken(userModel.token);
      await _localDataSource.saveUser(userModel);
      return Right(userModel.toEntity());
    } catch (e) {
      return Left(ErrorHandler.handleError(e));
    }
  }

  @override
  Future<Result<UserEntity>> register({
    required String phone,
    required String code,
    required String password,
  }) async {
    try {
      // Mock 场景下直接复用登录逻辑
      final userModel = await _remoteDataSource.login(
        phone: phone,
        password: password,
      );
      await _localDataSource.saveToken(userModel.token);
      await _localDataSource.saveUser(userModel);
      return Right(userModel.toEntity());
    } catch (e) {
      return Left(ErrorHandler.handleError(e));
    }
  }

  @override
  Future<void> logout() async {
    await _localDataSource.clear();
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final localUser = _localDataSource.getUser();
    if (localUser != null) {
      return localUser.toEntity();
    }
    return null;
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = _localDataSource.getToken();
    return token != null && token.isNotEmpty;
  }
}
