import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../domain/entities/category_entity.dart';

/// 首页分类横滑栏
///
/// 面试讲解点：
/// 分类横滑使用 ListView.builder 的原因：
/// 虽然分类数量不多（10个），但用 builder 模式是良好的习惯，
/// 如果分类数量变多也能保证性能。
class HomeCategoryBar extends StatelessWidget {
  const HomeCategoryBar({super.key, required this.categories});

  final List<CategoryEntity> categories;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    // 只显示一级分类中的前10个
    final rootCategories =
        categories.where((c) => c.isRoot).take(10).toList();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppDimens.spacingL),
            child: Text(
              '商品分类',
              style: TextStyle(
                fontSize: AppDimens.fontL,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: AppDimens.spacingM),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.spacingL,
              ),
              itemCount: rootCategories.length,
              itemBuilder: (context, index) {
                final category = rootCategories[index];
                return _CategoryItem(category: category);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  const _CategoryItem({required this.category});

  final CategoryEntity category;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // TODO: 跳转到分类页
      },
      borderRadius: BorderRadius.circular(AppDimens.radiusM),
      child: Container(
        width: 70,
        margin: const EdgeInsets.only(right: AppDimens.spacingM),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppDimens.radiusL),
              ),
              alignment: Alignment.center,
              child: Text(
                category.icon,
                style: const TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(height: AppDimens.spacingXS),
            Text(
              category.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: AppDimens.fontS,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
