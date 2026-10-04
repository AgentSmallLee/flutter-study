part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

/// 检查登录状态
class AuthCheckStatus extends AuthEvent {
  const AuthCheckStatus();
}

/// 登录成功
class AuthLoggedIn extends AuthEvent {
  const AuthLoggedIn(this.user);
  final UserEntity user;

  @override
  List<Object> get props => [user];
}

/// 登出
class AuthLoggedOut extends AuthEvent {
  const AuthLoggedOut();
}
