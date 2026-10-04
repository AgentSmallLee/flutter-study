import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/storage_keys.dart';
import '../models/user_model.dart';

/// 认证本地数据源
///
/// 负责 Token 和用户信息的持久化存储。
/// 为什么用 SharedPreferences 而不是 Hive？
/// Token 和用户信息是简单的 KV 存储，
/// shared_preferences 够用，且是 Flutter 生态最成熟的方案。
class AuthLocalDataSource {
  AuthLocalDataSource(this._prefs);

  final SharedPreferences _prefs;

  /// 保存 Token
  Future<void> saveToken(String token) async {
    await _prefs.setString(StorageKeys.userToken, token);
  }

  /// 获取 Token
  String? getToken() {
    return _prefs.getString(StorageKeys.userToken);
  }

  /// 保存用户信息
  Future<void> saveUser(UserModel user) async {
    await _prefs.setString(
      StorageKeys.userInfo,
      json.encode(user.toJson()),
    );
  }

  /// 获取用户信息
  UserModel? getUser() {
    final jsonStr = _prefs.getString(StorageKeys.userInfo);
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final map = json.decode(jsonStr) as Map<String, dynamic>;
      return UserModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  /// 清除认证信息
  Future<void> clear() async {
    await _prefs.remove(StorageKeys.userToken);
    await _prefs.remove(StorageKeys.userInfo);
  }
}
