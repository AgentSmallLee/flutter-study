import '../../domain/entities/user_entity.dart';

/// 用户数据模型
class UserModel {
  UserModel({
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

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int? ?? 0,
      username: json['username']?.toString() ?? '',
      nickname: json['nickname']?.toString() ?? '',
      avatar: json['avatar']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      token: json['token']?.toString() ?? '',
      level: json['level']?.toString() ?? '',
      points: json['points'] as int? ?? 0,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
    );
  }

  UserEntity toEntity() => UserEntity(
        id: id,
        username: username,
        nickname: nickname,
        avatar: avatar,
        phone: phone,
        token: token,
        level: level,
        points: points,
        balance: balance,
      );

  /// 从 entity 构造（用于本地存储）
  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      id: entity.id,
      username: entity.username,
      nickname: entity.nickname,
      avatar: entity.avatar,
      phone: entity.phone,
      token: entity.token,
      level: entity.level,
      points: entity.points,
      balance: entity.balance,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'nickname': nickname,
        'avatar': avatar,
        'phone': phone,
        'token': token,
        'level': level,
        'points': points,
        'balance': balance,
      };
}
