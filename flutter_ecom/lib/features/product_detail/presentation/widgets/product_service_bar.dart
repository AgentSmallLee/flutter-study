import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';

/// 服务保障栏
class ProductServiceBar extends StatelessWidget {
  const ProductServiceBar({
    super.key,
    required this.services,
    this.shipping = '',
  });

  final List<String> services;
  final String shipping;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.spacingL,
        vertical: AppDimens.spacingM,
      ),
      child: Column(
        children: [
          // 发货信息
          if (shipping.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AppDimens.spacingS),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_shipping_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      shipping,
                      style: const TextStyle(
                        fontSize: AppDimens.fontS,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // 服务保障
          Row(
            children: [
              const Icon(
                Icons.verified_outlined,
                size: 16,
                color: AppColors.success,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Wrap(
                  spacing: AppDimens.spacingL,
                  runSpacing: 4,
                  children: services
                      .map((s) => Text(
                            s,
                            style: const TextStyle(
                              fontSize: AppDimens.fontS,
                              color: AppColors.textSecondary,
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
