import 'package:intl/intl.dart';

/// 数字扩展方法
extension NumExtensions on num {
  /// 格式化为价格字符串（¥xxx.xx）
  String toPriceString({bool withSymbol = true}) {
    final formatter = NumberFormat.currency(
      locale: 'zh_CN',
      symbol: withSymbol ? '¥' : '',
      decimalDigits: 2,
    );
    return formatter.format(this);
  }

  /// 格式化为整数价格（¥xxx，当小数为 0 时省略）
  String toPriceIntString() {
    if (this == toInt()) {
      return '¥${toInt()}';
    }
    return toPriceString();
  }

  /// 万级数量格式化（例如 12000 → 1.2万）
  String toWanString() {
    if (this >= 10000) {
      final wan = this / 10000;
      return '${wan.toStringAsFixed(1)}万';
    }
    return toStringAsFixed(0);
  }

  /// 格式化为百分比
  String toPercentString({int decimalDigits = 1}) {
    return '${(this * 100).toStringAsFixed(decimalDigits)}%';
  }
}
