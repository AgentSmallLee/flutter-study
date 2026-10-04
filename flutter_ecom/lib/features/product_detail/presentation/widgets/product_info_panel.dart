import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/extensions/num_extensions.dart';
import '../../../../core/extensions/string_extensions.dart';
import '../../domain/entities/product_detail_entity.dart';

/// 商品信息面板（价格、标题、标签、销量等）
class ProductInfoPanel extends StatelessWidget {
  const ProductInfoPanel({super.key, required this.product});

  final ProductDetailEntity product;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.all(AppDimens.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 价格行
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                product.price.toPriceString(),
                style: const TextStyle(
                  fontSize: AppDimens.fontXXL,
                  fontWeight: FontWeight.bold,
                  color: AppColors.price,
                ),
              ),
              const SizedBox(width: AppDimens.spacingS),
              if (product.hasDiscount)
                Text(
                  product.originalPrice!.toPriceString(),
                  style: const TextStyle(
                    fontSize: AppDimens.fontS,
                    color: AppColors.textHint,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              const Spacer(),
              // 标签
              if (product.tags.isNotEmpty)
                Row(
                  children: product.tags
                      .take(2)
                      .map((tag) => Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              tag,
                              style: const TextStyle(
                                fontSize: AppDimens.fontXS,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ))
                      .toList(),
                ),
            ],
          ),
          const SizedBox(height: AppDimens.spacingM),
          // 标题
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: AppDimens.fontL,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppDimens.spacingM),
          // 销量 / 评分 / 评价数
          Row(
            children: [
              _buildInfoItem('销量', product.salesCount.toWanString()),
              Container(
                width: 1,
                height: 12,
                color: AppColors.divider,
                margin:
                    const EdgeInsets.symmetric(horizontal: AppDimens.spacingM),
              ),
              _buildInfoItem('评分', '${product.rating}'),
              Container(
                width: 1,
                height: 12,
                color: AppColors.divider,
                margin:
                    const EdgeInsets.symmetric(horizontal: AppDimens.spacingM),
              ),
              _buildInfoItem('评价', '${product.reviewCount}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: AppDimens.fontS,
            color: AppColors.textHint,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: AppDimens.fontS,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
