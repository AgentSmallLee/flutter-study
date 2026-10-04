import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_dimens.dart';

/// 通用加载指示器
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({
    super.key,
    this.size = 40.0,
    this.strokeWidth = 3.0,
    this.color = AppColors.primary,
    this.text,
  });

  final double size;
  final double strokeWidth;
  final Color color;
  final String? text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: strokeWidth,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          if (text != null) ...[
            SizedBox(height: AppDimens.spacingM),
            Text(
              text!,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: AppDimens.fontM,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
