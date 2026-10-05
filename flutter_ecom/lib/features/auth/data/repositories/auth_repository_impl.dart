import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart' show MissingPluginException;

import '../../../../core/bridge/native_bridge.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

/// 认证 Repository 实现
///
/// 面试讲解点：
/// 混合开发模式下，登录态由原生维护，Flutter 侧做本地缓存。
///
/// 策略：本地缓存 + 原生兜底
/// 1. 启动时调用 syncNativeToken()，从原生同步最新的登录态到本地
/// 2. 本地有 token 时，直接用本地缓存，减少 Channel 调用
/// 3. 登录操作走原生（nativeLogin），登录成功后同步到本地
/// 4. 登出操作也走原生，同步清理两端状态
///
/// 为什么不让 Flutter 自己维护登录态？
/// - App 是混合开发的，原生页面也需要登录态，统一由原生管理最合理
/// - 避免出现「原生登录了 Flutter 没登录」「Flutter 登出了原生还登录着」的不一致问题
/// - Token 刷新、失效等逻辑原生侧已经有成熟方案，Flutter 不用重复实现
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remoteDataSource, this._localDataSource);

  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  /// 是否使用原生登录态（混合开发模式）
  ///
  /// 面试讲解点：
  /// 通过配置切换两种模式：
  /// - true：混合开发模式，登录态由原生维护，Flutter 通过 Channel 同步
  /// - false：Flutter 独立运行模式，自己管理登录态（调试用）
  static const bool useNativeAuth = true;

  @override
  Future<Result<UserEntity>> login({
    required String phone,
    required String password,
  }) async {
    try {
      if (useNativeAuth) {
        // 混合开发模式：调用原生登录
        try {
          final result = await NativeBridge().nativeLogin();
          if (result == null) {
            return const Left(UnknownFailure('登录失败'));
          }
          final userModel = UserModel.fromJson(result);
          await _localDataSource.saveToken(userModel.token);
          await _localDataSource.saveUser(userModel);
          return Right(userModel.toEntity());
        } on MissingPluginException {
          // 面试讲解点：
          // 捕获 MissingPluginException 自动降级——
          // 纯 Flutter 运行（flutter run）时，原生没有注册 MethodChannel 实现，
          // 会抛 MissingPluginException。这时候自动降级为远程接口登录，
          // 保证纯 Flutter 调试和混合开发两种模式都能正常工作。
          return _loginWithRemote(phone, password);
        }
      } else {
        // 独立运行模式：走远程接口
        return _loginWithRemote(phone, password);
      }
    } catch (e) {
      return Left(ErrorHandler.handleError(e));
    }
  }

  /// 远程接口登录（抽取公共方法，避免重复代码）
  Future<Result<UserEntity>> _loginWithRemote(
    String phone,
    String password,
  ) async {
    final userModel = await _remoteDataSource.login(
      phone: phone,
      password: password,
    );
    await _localDataSource.saveToken(userModel.token);
    await _localDataSource.saveUser(userModel);
    return Right(userModel.toEntity());
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
    if (useNativeAuth) {
      // 混合开发模式：通知原生登出，再清理本地缓存
      // 原生登出失败也清理本地，保证 Flutter 侧状态一致
      try {
        await NativeBridge().logout();
      } catch (_) {}
    }
    await _localDataSource.clear();
  }

  /// 从原生同步登录态到 Flutter 本地
  ///
  /// 面试讲解点：
  /// App 启动时调用一次，把原生的登录态同步到 Flutter 本地缓存。
  /// 这样后续 Dio 拦截器可以直接读本地 token，不用每次请求都走 Channel，
  /// 既提升性能，也避免了 Dio 拦截器同步调用 Channel 的问题
  /// （Dio 的 onRequest 拦截器是同步的，不能直接 await Channel 调用）。
  Future<void> syncNativeToken() async {
    if (!useNativeAuth) return;

    try {
      final token = await NativeBridge().getToken();
      if (token != null && token.isNotEmpty) {
        await _localDataSource.saveToken(token);
      }
    } catch (_) {
      // 同步失败不影响启动，后续请求时 401 再处理
    }
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    // 混合开发模式下，如果本地没有用户信息，先尝试从原生同步登录态
    if (useNativeAuth) {
      final localToken = _localDataSource.getToken();
      if (localToken == null || localToken.isEmpty) {
        await syncNativeToken();
      }
    }
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
