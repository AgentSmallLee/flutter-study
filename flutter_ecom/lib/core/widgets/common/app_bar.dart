import 'package:flutter/material.dart';
import '../../constants/app_dimens.dart';

/// 通用 AppBar
///
/// 封装常用的 AppBar 样式，统一标题、返回按钮、右侧操作按钮。
class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CommonAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.showBack = true,
    this.backgroundColor,
    this.elevation = 0,
    this.actions,
    this.centerTitle = true,
    this.onBack,
  });

  final String? title;
  final Widget? titleWidget;
  final bool showBack;
  final Color? backgroundColor;
  final double elevation;
  final List<Widget>? actions;
  final bool centerTitle;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: titleWidget ?? (title != null ? Text(title!) : null),
      centerTitle: centerTitle,
      backgroundColor: backgroundColor,
      elevation: elevation,
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            )
          : null,
      actions: actions,
      scrolledUnderElevation: 0,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(AppDimens.appBarHeight);
}
