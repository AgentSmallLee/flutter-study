import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_dimens.dart';

/// 空状态组件
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    this.title = '暂无数据',
    this.subtitle,
    this.onRetry,
    this.buttonText,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onRetry;
  final String? buttonText;

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
              color: AppColors.textHint,
            ),
            SizedBox(height: AppDimens.spacingL),
            Text(
              title,
              style: TextStyle(
                fontSize: AppDimens.fontL,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (subtitle != null) ...[
              SizedBox(height: AppDimens.spacingS),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: AppDimens.fontS,
                  color: AppColors.textHint,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              SizedBox(height: AppDimens.spacingXL),
              SizedBox(
                width: 140,
                child: ElevatedButton(
                  onPressed: onRetry,
                  child: Text(buttonText ?? '重新加载'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
