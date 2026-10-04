import 'package:flutter/material.dart';
import '../constants/app_dimens.dart';

/// BuildContext 扩展方法
///
/// 面试讲解点：
/// Dart 的 extension 机制可以在不修改原类的情况下为其添加方法，
/// 这里封装一些常用的 MediaQuery 和 Theme 获取方式，让代码更简洁。
extension ContextExtensions on BuildContext {
  /// 获取屏幕尺寸
  Size get screenSize => MediaQuery.of(this).size;

  /// 屏幕宽度
  double get screenWidth => MediaQuery.of(this).size.width;

  /// 屏幕高度
  double get screenHeight => MediaQuery.of(this).size.height;

  /// 顶部安全区域高度（状态栏）
  double get statusBarHeight => MediaQuery.of(this).padding.top;

  /// 底部安全区域高度
  double get bottomBarHeight => MediaQuery.of(this).padding.bottom;

  /// 获取 ThemeData
  ThemeData get theme => Theme.of(this);

  /// 获取 TextTheme
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// 获取 ColorScheme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// 获取亮色/暗色模式
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// 获取主色调
  Color get primaryColor => Theme.of(this).primaryColor;

  /// 隐藏键盘
  void hideKeyboard() => FocusScope.of(this).unfocus();

  /// 便捷的垂直间距 SizedBox
  Widget verticalSpace([double height = AppDimens.spacingM]) =>
      SizedBox(height: height);

  /// 便捷的水平间距 SizedBox
  Widget horizontalSpace([double width = AppDimens.spacingM]) =>
      SizedBox(width: width);
}
