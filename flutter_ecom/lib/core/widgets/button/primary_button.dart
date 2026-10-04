import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_dimens.dart';

/// 主按钮组件
///
/// 统一的主按钮样式，支持加载状态、禁用状态。
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.width = double.infinity,
    this.height = AppDimens.buttonHeight,
    this.borderRadius = AppDimens.radiusM,
    this.backgroundColor,
    this.textColor,
    this.fontSize = AppDimens.fontL,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final double width;
  final double height;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? textColor;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final isDisabled = !isEnabled || isLoading;
    final bgColor = backgroundColor ?? AppColors.primary;

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: textColor ?? Colors.white,
          disabledBackgroundColor: bgColor.withOpacity(0.5),
          disabledForegroundColor: Colors.white.withOpacity(0.7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                text,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
