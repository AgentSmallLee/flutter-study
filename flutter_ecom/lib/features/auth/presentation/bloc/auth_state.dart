part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

/// 初始状态（正在检查登录状态）
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// 已认证
class Authenticated extends AuthState {
  const Authenticated(this.user);
  final UserEntity user;

  @override
  List<Object> get props => [user];
}

/// 未认证
class Unauthenticated extends AuthState {
  const Unauthenticated();
}
