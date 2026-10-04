/// 本地存储 Key 常量
class StorageKeys {
  StorageKeys._();

  // ============ 用户相关 ============
  /// 用户 Token
  static const String userToken = 'user_token';

  /// 用户信息 JSON
  static const String userInfo = 'user_info';

  // ============ 搜索相关 ============
  /// 搜索历史记录
  static const String searchHistory = 'search_history';

  // ============ 购物车相关 ============
  /// 购物车数据（Hive Box 名称）
  static const String cartBox = 'cart_box';

  // ============ 应用设置 ============
  /// 主题模式（light / dark / system）
  static const String themeMode = 'theme_mode';

  /// 语言设置
  static const String locale = 'locale';

  /// 是否首次启动
  static const String isFirstLaunch = 'is_first_launch';
}
