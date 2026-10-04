/// 字符串扩展方法
extension StringExtensions on String {
  /// 是否为有效手机号（中国大陆）
  bool get isValidPhone {
    final regex = RegExp(r'^1[3-9]\d{9}$');
    return regex.hasMatch(this);
  }

  /// 是否为有效邮箱
  bool get isValidEmail {
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(this);
  }

  /// 密码强度（6-20位，包含字母和数字）
  bool get isValidPassword {
    if (length < 6 || length > 20) return false;
    // 至少包含字母和数字
    final hasLetter = contains(RegExp(r'[a-zA-Z]'));
    final hasDigit = contains(RegExp(r'\d'));
    return hasLetter && hasDigit;
  }

  /// 是否为有效验证码（6位数字）
  bool get isValidCode {
    final regex = RegExp(r'^\d{6}$');
    return regex.hasMatch(this);
  }

  /// 字符串不为 null 且不为空
  bool get isNullOrEmpty => this == null || isEmpty; // ignore: unnecessary_null_comparison

  /// 字符串不为 null 且不为空
  bool get isNotNullOrEmpty => !isNullOrEmpty;

  /// 手机号脱敏（中间4位用*代替）
  String get maskPhone {
    if (length != 11) return this;
    return '${substring(0, 3)}****${substring(7)}';
  }

  /// 限制字符串长度，超出部分用 ... 代替
  String ellipsis(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}...';
  }
}
