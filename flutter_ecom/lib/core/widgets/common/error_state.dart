import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_dimens.dart';

/// 错误状态组件
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    this.icon = Icons.error_outline,
    this.title = '加载失败',
    this.message = '请检查网络后重试',
    required this.onRetry,
    this.buttonText = '点击重试',
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onRetry;
  final String buttonText;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppDimens.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 80,
              color: AppColors.error,
            ),
            SizedBox(height: AppDimens.spacingL),
            Text(
              title,
              style: TextStyle(
                fontSize: AppDimens.fontL,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: AppDimens.spacingS),
            Text(
              message,
              style: TextStyle(
                fontSize: AppDimens.fontS,
                color: AppColors.textHint,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppDimens.spacingXL),
            SizedBox(
              width: 140,
              child: ElevatedButton(
                onPressed: onRetry,
                child: Text(buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
