import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/extensions/num_extensions.dart';
import '../../../../core/widgets/common/cache_network_image.dart';
import '../../../../core/widgets/common/loading_indicator.dart';
import '../../../home/domain/entities/product_entity.dart';
import '../bloc/search_bloc.dart';
import '../bloc/search_event.dart';
import '../bloc/search_state.dart';

/// 搜索页面
///
/// 面试讲解点：
/// 搜索页的状态机设计：
/// - 初始状态：搜索历史 + 热门搜索
/// - 输入中：展示清除按钮
/// - 搜索中：loading
/// - 搜索结果：商品列表 + 加载更多
///
/// 输入防抖：使用 Debouncer，避免每次按键都发请求。
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late final SearchBloc _searchBloc;

  @override
  void initState() {
    super.initState();
    // 在 initState 中创建 Bloc 实例，避免每次 build 都创建新实例
    _searchBloc = getIt<SearchBloc>()..add(const SearchInitialized());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _searchBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _searchBloc,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(context),
        body: BlocBuilder<SearchBloc, SearchState>(
          builder: (context, state) {
            switch (state.status) {
              case SearchStatus.initial:
              case SearchStatus.suggestion:
                return _buildInitialView(context, state);
              case SearchStatus.loading:
                return const LoadingIndicator();
              case SearchStatus.success:
                return _buildResultView(context, state);
              case SearchStatus.failure:
                return _buildErrorView(context, state);
            }
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0.5,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: Container(
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppDimens.radiusFull),
        ),
        child: Row(
          children: [
            const SizedBox(width: AppDimens.spacingM),
            const Icon(Icons.search, size: 20, color: AppColors.textHint),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: (value) {
                  context
                      .read<SearchBloc>()
                      .add(SearchKeywordChanged(value));
                },
                onSubmitted: (value) {
                  context
                      .read<SearchBloc>()
                      .add(SearchSubmitted(value));
                },
                decoration: const InputDecoration(
                  hintText: '搜索商品',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                  hintStyle: TextStyle(
                    fontSize: AppDimens.fontM,
                    color: AppColors.textHint,
                  ),
                ),
                style: const TextStyle(
                  fontSize: AppDimens.fontM,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            BlocBuilder<SearchBloc, SearchState>(
              builder: (context, state) {
                if (state.keyword.isEmpty) {
                  return const SizedBox.shrink();
                }
                return IconButton(
                  icon: const Icon(Icons.cancel, size: 18, color: AppColors.textHint),
                  onPressed: () {
                    _controller.clear();
                    context
                        .read<SearchBloc>()
                        .add(const SearchKeywordChanged(''));
                    _focusNode.requestFocus();
                  },
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            final keyword = _controller.text.trim();
            if (keyword.isNotEmpty) {
              context.read<SearchBloc>().add(SearchSubmitted(keyword));
            }
          },
          child: const Text('搜索'),
        ),
      ],
    );
  }

  // ========== 初始状态：历史 + 热门 ==========

  Widget _buildInitialView(BuildContext context, SearchState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimens.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 搜索历史
          if (state.history.isNotEmpty) ...[
            _buildSectionHeader(
              '搜索历史',
              onClear: () => context
                  .read<SearchBloc>()
                  .add(const SearchHistoryCleared()),
            ),
            const SizedBox(height: AppDimens.spacingM),
            _buildHistoryTags(context, state.history),
            const SizedBox(height: AppDimens.spacingXL),
          ],
          // 热门搜索
          _buildSectionHeader('热门搜索'),
          const SizedBox(height: AppDimens.spacingM),
          _buildHotTags(context, state.hotKeywords),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onClear}) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: AppDimens.fontM,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        if (onClear != null)
          InkWell(
            onTap: onClear,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.delete_outline, size: 16, color: AppColors.textHint),
                SizedBox(width: 4),
                Text(
                  '清空',
                  style: TextStyle(
                    fontSize: AppDimens.fontS,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildHistoryTags(BuildContext context, List<String> history) {
    return Wrap(
      spacing: AppDimens.spacingS,
      runSpacing: AppDimens.spacingS,
      children: history.map((keyword) {
        return InkWell(
          onTap: () {
            _controller.text = keyword;
            context.read<SearchBloc>().add(SearchSubmitted(keyword));
          },
          borderRadius: BorderRadius.circular(AppDimens.radiusFull),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.spacingM,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppDimens.radiusFull),
            ),
            child: Text(
              keyword,
              style: const TextStyle(
                fontSize: AppDimens.fontS,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHotTags(BuildContext context, List<String> hotKeywords) {
    return Wrap(
      spacing: AppDimens.spacingS,
      runSpacing: AppDimens.spacingS,
      children: hotKeywords.asMap().entries.map((entry) {
        final index = entry.key;
        final keyword = entry.value;
        final isTop3 = index < 3;
        return InkWell(
          onTap: () {
            _controller.text = keyword;
            context.read<SearchBloc>().add(SearchSubmitted(keyword));
          },
          borderRadius: BorderRadius.circular(AppDimens.radiusS),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.spacingM,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: isTop3 ? AppColors.primaryLight : AppColors.white,
              borderRadius: BorderRadius.circular(AppDimens.radiusS),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isTop3) ...[
                  Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: AppDimens.fontXS,
                      fontWeight: FontWeight.bold,
                      color: index == 0
                          ? AppColors.price
                          : (index == 1
                              ? AppColors.warning
                              : AppColors.success),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  keyword,
                  style: TextStyle(
                    fontSize: AppDimens.fontS,
                    color: isTop3
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ========== 搜索结果 ==========

  Widget _buildResultView(BuildContext context, SearchState state) {
    if (state.products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_outlined,
              size: 80,
              color: AppColors.textHint.withOpacity(0.5),
            ),
            const SizedBox(height: AppDimens.spacingM),
            const Text(
              '未找到相关商品',
              style: TextStyle(
                fontSize: AppDimens.fontL,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppDimens.spacingM),
      itemCount: state.products.length + 1,
      itemBuilder: (context, index) {
        // 加载更多
        if (index == state.products.length) {
          if (state.isLoadingMore) {
            return const Padding(
              padding: EdgeInsets.all(AppDimens.spacingL),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          if (!state.hasMore) {
            return const Padding(
              padding: EdgeInsets.all(AppDimens.spacingL),
              child: Center(
                child: Text(
                  '— 没有更多了 —',
                  style: TextStyle(color: AppColors.textHint),
                ),
              ),
            );
          }
          // 触发加载更多
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<SearchBloc>().add(const SearchLoadMore());
          });
          return const SizedBox.shrink();
        }
        final product = state.products[index];
        return _ProductListItem(
          product: product,
          onTap: () => context.push('/product/${product.id}'),
        );
      },
    );
  }

  Widget _buildErrorView(BuildContext context, SearchState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: AppDimens.spacingM),
          Text(
            state.errorMessage ?? '搜索失败',
            style: const TextStyle(
              fontSize: AppDimens.fontM,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimens.spacingL),
          ElevatedButton(
            onPressed: () {
              context
                  .read<SearchBloc>()
                  .add(SearchSubmitted(state.keyword));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('重新搜索'),
          ),
        ],
      ),
    );
  }
}

/// 搜索结果商品列表项
class _ProductListItem extends StatelessWidget {
  const _ProductListItem({required this.product, required this.onTap});

  final ProductEntity product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimens.spacingM),
        padding: const EdgeInsets.all(AppDimens.spacingS),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimens.radiusS),
              child: AppNetworkImage(
                imageUrl: product.imageUrl,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: AppDimens.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: AppDimens.fontS,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // 标签
                  if (product.tags.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        product.tags.first,
                        style: const TextStyle(
                          fontSize: AppDimens.fontXS,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        product.price.toPriceString(),
                        style: const TextStyle(
                          fontSize: AppDimens.fontL,
                          fontWeight: FontWeight.bold,
                          color: AppColors.price,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '已售${product.salesCount.toWanString()}',
                        style: const TextStyle(
                          fontSize: AppDimens.fontXS,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
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
