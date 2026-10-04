import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';

/// 规格选择栏
class ProductSpecBar extends StatelessWidget {
  const ProductSpecBar({
    super.key,
    this.selectedSpecs = '请选择规格',
    required this.onTap,
  });

  final String selectedSpecs;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: AppColors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.spacingL,
          vertical: AppDimens.spacingM,
        ),
        child: Row(
          children: [
            const Text(
              '规格',
              style: TextStyle(
                fontSize: AppDimens.fontM,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: AppDimens.spacingL),
            Expanded(
              child: Text(
                selectedSpecs,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: AppDimens.fontM,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}
