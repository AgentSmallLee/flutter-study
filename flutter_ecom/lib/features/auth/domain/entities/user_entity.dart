import 'package:equatable/equatable.dart';

/// 用户实体
class UserEntity extends Equatable {
  const UserEntity({
    required this.id,
    required this.username,
    required this.nickname,
    required this.avatar,
    required this.phone,
    required this.token,
    this.level = '',
    this.points = 0,
    this.balance = 0.0,
  });

  final int id;
  final String username;
  final String nickname;
  final String avatar;
  final String phone;
  final String token;
  final String level;
  final int points;
  final double balance;

  /// 是否登录
  bool get isLoggedIn => token.isNotEmpty;

  @override
  List<Object> get props => [
        id,
        username,
        nickname,
        avatar,
        phone,
        token,
        level,
        points,
        balance,
      ];

  /// 空用户（未登录）
  static const UserEntity empty = UserEntity(
    id: 0,
    username: '',
    nickname: '',
    avatar: '',
    phone: '',
    token: '',
  );
}
