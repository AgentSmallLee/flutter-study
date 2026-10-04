import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/common/cache_network_image.dart';
import '../../../../core/widgets/common/loading_indicator.dart';
import '../../../../core/widgets/common/error_state.dart';
import '../../../home/domain/entities/category_entity.dart';
import '../bloc/category_bloc.dart';
import '../bloc/category_event.dart';
import '../bloc/category_state.dart';

/// 分类页面
///
/// 面试讲解点：
/// 经典的左右联动布局：左侧一级分类 ListView，右侧内容区。
/// 点击左侧分类，右侧展示对应的二级分类和商品。
/// 使用 Row + Expanded 实现左右两栏的固定比例布局。
class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocProvider.value(
      value: getIt<CategoryBloc>(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('分类'),
          centerTitle: true,
          backgroundColor: AppColors.white,
          elevation: 0.5,
        ),
        body: BlocBuilder<CategoryBloc, CategoryState>(
          builder: (context, state) {
            if (state.status == CategoryStatus.loading) {
              return const LoadingIndicator();
            }
            if (state.status == CategoryStatus.failure) {
              return ErrorState(
                onRetry: () => context
                    .read<CategoryBloc>()
                    .add(const CategoryLoaded()),
              );
            }
            if (state.status == CategoryStatus.success) {
              return _buildContentView(context, state);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildContentView(BuildContext context, CategoryState state) {
    return Row(
      children: [
        // 左侧一级分类
        _buildLeftCategoryList(context, state),
        // 右侧内容
        Expanded(
          child: _buildRightContent(context, state),
        ),
      ],
    );
  }

  Widget _buildLeftCategoryList(
    BuildContext context,
    CategoryState state,
  ) {
    final rootCategories = state.rootCategories;
    return Container(
      width: 90,
      color: AppColors.white,
      child: ListView.builder(
        itemCount: rootCategories.length,
        itemBuilder: (context, index) {
          final category = rootCategories[index];
          final isSelected = category.id == state.selectedRootId;
          return InkWell(
            onTap: () {
              context.read<CategoryBloc>().add(CategorySelected(category.id));
            },
            child: Container(
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.background : Colors.transparent,
                border: Border(
                  left: BorderSide(
                    color:
                        isSelected ? AppColors.primary : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
              child: Text(
                category.name,
                style: TextStyle(
                  fontSize: AppDimens.fontS,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textPrimary,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRightContent(
    BuildContext context,
    CategoryState state,
  ) {
    final subCategories = state.subCategories;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimens.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 二级分类标题
          const Text(
            '全部分类',
            style: TextStyle(
              fontSize: AppDimens.fontM,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimens.spacingM),
          // 二级分类网格
          if (subCategories.isNotEmpty)
            _buildSubCategoryGrid(subCategories),
          const SizedBox(height: AppDimens.spacingL),
          // 猜你喜欢
          const Text(
            '猜你喜欢',
            style: TextStyle(
              fontSize: AppDimens.fontM,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimens.spacingM),
          // 推荐商品（占位，后续接搜索/推荐接口）
          _buildProductPlaceholder(),
        ],
      ),
    );
  }

  Widget _buildSubCategoryGrid(List<CategoryEntity> subCategories) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: AppDimens.spacingM,
        crossAxisSpacing: AppDimens.spacingM,
        childAspectRatio: 0.85,
      ),
      itemCount: subCategories.length,
      itemBuilder: (context, index) {
        final category = subCategories[index];
        return _SubCategoryItem(category: category);
      },
    );
  }

  Widget _buildProductPlaceholder() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppDimens.spacingM,
        crossAxisSpacing: AppDimens.spacingM,
        childAspectRatio: 0.7,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppDimens.radiusM),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppDimens.radiusM),
                  ),
                  child: AppNetworkImage(
                    imageUrl:
                        'https://picsum.photos/seed/cat$index/300/300',
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppDimens.spacingS),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '推荐商品 $index',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: AppDimens.fontS,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '¥99.00',
                      style: TextStyle(
                        fontSize: AppDimens.fontS,
                        fontWeight: FontWeight.bold,
                        color: AppColors.price,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 二级分类项
class _SubCategoryItem extends StatelessWidget {
  const _SubCategoryItem({required this.category});

  final CategoryEntity category;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // 跳转到商品列表（用搜索页占位）
        context.push('/search');
      },
      borderRadius: BorderRadius.circular(AppDimens.radiusS),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppDimens.radiusS),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              category.icon,
              style: const TextStyle(fontSize: 24),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            category.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: AppDimens.fontXS,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
