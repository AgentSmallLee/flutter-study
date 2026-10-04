import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/extensions/num_extensions.dart';
import '../../../../core/extensions/string_extensions.dart';
import '../../../../core/widgets/common/cache_network_image.dart';
import '../../../../core/widgets/common/empty_state.dart';
import '../../../../core/widgets/common/error_state.dart';
import '../../../../core/widgets/common/loading_indicator.dart';
import '../../domain/entities/product_entity.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';
import '../widgets/home_banner.dart';
import '../widgets/home_category_bar.dart';

/// 首页
///
/// 面试讲解点：
/// HomePage 使用 BlocProvider.value 从 getIt 获取 HomeBloc 实例。
/// UI 构建遵循「状态驱动」原则：根据 state 的类型构建不同的 UI。
///
/// 页面结构：
/// - AppBar：搜索框 + 消息按钮
/// - EasyRefresh：包裹 ListView，支持下拉刷新
/// - ListView 内部包含：Banner + 分类横滑 + 推荐商品网格 + 加载更多
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<HomeBloc>(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(context),
        body: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            // 首次加载中
            if (state is HomeLoading) {
              return const LoadingIndicator();
            }
            // 加载失败
            if (state is HomeFailure) {
              return ErrorState(
                message: state.message,
                onRetry: () =>
                    context.read<HomeBloc>().add(const HomeInitialEvent()),
              );
            }
            // 加载成功
            if (state is HomeSuccess) {
              return _buildSuccessView(context, state);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  /// 构建 AppBar（搜索框样式）
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      titleSpacing: 0,
      backgroundColor: AppColors.primary,
      elevation: 0,
      title: InkWell(
        onTap: () {
          context.push('/search');
        },
        child: Container(
          height: 36,
          margin: const EdgeInsets.only(right: AppDimens.spacingL),
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.spacingM),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppDimens.radiusFull),
          ),
          child: const Row(
            children: [
              Icon(Icons.search, size: 20, color: AppColors.textHint),
              SizedBox(width: 8),
              Text(
                '搜索商品',
                style: TextStyle(
                  color: AppColors.textHint,
                  fontSize: AppDimens.fontM,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.message_outlined, color: Colors.white),
          onPressed: () {
            // TODO: 消息中心
          },
        ),
      ],
    );
  }

  /// 构建成功状态视图
  Widget _buildSuccessView(BuildContext context, HomeSuccess state) {
    return EasyRefresh(
      onRefresh: () async {
        context.read<HomeBloc>().add(const HomeRefreshEvent());
      },
      child: ListView(
        children: [
          const SizedBox(height: AppDimens.spacingM),
          // Banner 轮播
          HomeBanner(banners: state.banners),
          // 分类横滑
          HomeCategoryBar(categories: state.categories),
          // 推荐商品标题
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppDimens.spacingL),
            child: Row(
              children: [
                Text(
                  '为你推荐',
                  style: TextStyle(
                    fontSize: AppDimens.fontL,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.spacingS),
          // 商品网格
          SliverGridWidget(
            products: state.products,
            isLoadingMore: state.isLoadingMore,
            hasMore: state.hasMore,
            onLoadMore: () {
              context.read<HomeBloc>().add(const HomeLoadMoreEvent());
            },
          ),
          // 加载更多指示器
          if (state.isLoadingMore)
            const Padding(
              padding: EdgeInsets.all(AppDimens.spacingL),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          // 没有更多了
          if (!state.hasMore && state.products.isNotEmpty)
            const Padding(
              padding: EdgeInsets.all(AppDimens.spacingL),
              child: Center(
                child: Text(
                  '— 没有更多了 —',
                  style: TextStyle(color: AppColors.textHint),
                ),
              ),
            ),
          // 空状态
          if (state.products.isEmpty)
            const Padding(
              padding: EdgeInsets.all(AppDimens.spacingXL * 2),
              child: EmptyState(title: '暂无商品'),
            ),
          const SizedBox(height: AppDimens.spacingL),
        ],
      ),
    );
  }
}

/// 商品网格组件
///
/// 面试讲解点：
/// 这里不用 GridView.builder 而是用 SliverGrid 包装，
/// 因为父级是 ListView（shrinkWrap + NeverScrollableScrollPhysics），
/// 这样可以和其他组件一起滚动。
/// 用 addPostFrameCallback 检测是否到达倒数第二项，触发加载更多。
class SliverGridWidget extends StatelessWidget {
  const SliverGridWidget({
    super.key,
    required this.products,
    required this.isLoadingMore,
    required this.hasMore,
    required this.onLoadMore,
  });

  final List<ProductEntity> products;
  final bool isLoadingMore;
  final bool hasMore;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.spacingL),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppDimens.spacingM,
        crossAxisSpacing: AppDimens.spacingM,
        childAspectRatio: 0.68,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        // 到达倒数第二项时加载更多
        if (index == products.length - 2 && !isLoadingMore && hasMore) {
          WidgetsBinding.instance.addPostFrameCallback((_) => onLoadMore());
        }
        return _ProductCard(product: product);
      },
    );
  }
}

/// 商品卡片组件
class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final ProductEntity product;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        context.push('/product/${product.id}');
      },
      borderRadius: BorderRadius.circular(AppDimens.radiusM),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 商品图片
            Expanded(
              child: Stack(
                children: [
                  AppNetworkImage(
                    imageUrl: product.imageUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppDimens.radiusM),
                    ),
                  ),
                  // 标签
                  if (product.tags.isNotEmpty)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          product.tags.first,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: AppDimens.fontXS,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // 商品信息
            Padding(
              padding: const EdgeInsets.all(AppDimens.spacingS),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题
                  Text(
                    product.name.ellipsis(20),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: AppDimens.fontS,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // 价格
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        product.price.toPriceString(),
                        style: const TextStyle(
                          fontSize: AppDimens.fontM,
                          fontWeight: FontWeight.bold,
                          color: AppColors.price,
                        ),
                      ),
                      const SizedBox(width: 4),
                      if (product.hasDiscount)
                        Text(
                          product.originalPrice!.toPriceString(),
                          style: const TextStyle(
                            fontSize: AppDimens.fontXS,
                            color: AppColors.textHint,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // 销量
                  Text(
                    '已售 ${product.salesCount.toWanString()}',
                    style: const TextStyle(
                      fontSize: AppDimens.fontXS,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
