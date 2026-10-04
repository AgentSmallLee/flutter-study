import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/extensions/num_extensions.dart';
import '../../../../core/widgets/common/cache_network_image.dart';
import '../../domain/entities/cart_item_entity.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_event.dart';
import '../bloc/cart_state.dart';

/// 购物车页面
///
/// 面试讲解点：
/// 购物车使用全局 CartBloc，任何页面修改购物车后这里都会同步更新。
/// 左滑删除、数量加减、全选等都是通过 Event 驱动状态变化。
class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<CartBloc>(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('购物车'),
          centerTitle: true,
          backgroundColor: AppColors.white,
          elevation: 0.5,
          actions: [
            BlocBuilder<CartBloc, CartState>(
              builder: (context, state) {
                if (state.items.isEmpty) return const SizedBox.shrink();
                return TextButton(
                  onPressed: () {
                    // TODO: 编辑模式切换
                  },
                  child: const Text(
                    '管理',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: AppDimens.fontM,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: BlocBuilder<CartBloc, CartState>(
          builder: (context, state) {
            if (state.items.isEmpty) {
              return _buildEmptyState(context);
            }
            return _buildCartList(context, state);
          },
        ),
        bottomNavigationBar:
            BlocBuilder<CartBloc, CartState>(
          builder: (context, state) {
            if (state.items.isEmpty) {
              return const SizedBox.shrink();
            }
            return _buildBottomBar(context, state);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: AppColors.textHint.withOpacity(0.5),
          ),
          const SizedBox(height: AppDimens.spacingL),
          const Text(
            '购物车还是空的',
            style: TextStyle(
              fontSize: AppDimens.fontL,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimens.spacingM),
          const Text(
            '快去挑选心仪的商品吧',
            style: TextStyle(
              fontSize: AppDimens.fontS,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: AppDimens.spacingXL),
          SizedBox(
            width: 160,
            child: ElevatedButton(
              onPressed: () {
                // TODO: 跳转到首页
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                ),
                elevation: 0,
              ),
              child: const Text('去逛逛'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartList(BuildContext context, CartState state) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppDimens.spacingL),
      itemCount: state.items.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: AppDimens.spacingM),
      itemBuilder: (context, index) {
        final item = state.items[index];
        return _CartItemCard(item: item);
      },
    );
  }

  Widget _buildBottomBar(BuildContext context, CartState state) {
    return Container(
      padding: EdgeInsets.only(
        left: AppDimens.spacingL,
        right: AppDimens.spacingL,
        top: AppDimens.spacingS,
        bottom: AppDimens.spacingS + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // 全选
            InkWell(
              onTap: () {
                context.read<CartBloc>().add(
                      CartSelectAllToggled(!state.isAllSelected),
                    );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    state.isAllSelected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: state.isAllSelected
                        ? AppColors.primary
                        : AppColors.textHint,
                    size: 22,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '全选',
                    style: TextStyle(
                      fontSize: AppDimens.fontS,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // 合计
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '合计: ',
                      style: TextStyle(
                        fontSize: AppDimens.fontS,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      state.selectedTotalPrice.toPriceString(),
                      style: const TextStyle(
                        fontSize: AppDimens.fontL,
                        fontWeight: FontWeight.bold,
                        color: AppColors.price,
                      ),
                    ),
                  ],
                ),
                Text(
                  '已选 ${state.selectedCount} 件',
                  style: const TextStyle(
                    fontSize: AppDimens.fontXS,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppDimens.spacingM),
            // 结算按钮
            SizedBox(
              width: 110,
              height: AppDimens.buttonHeight,
              child: ElevatedButton(
                onPressed: state.selectedCount > 0
                    ? () {
                        // TODO: 去结算
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.textHint,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimens.radiusFull),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '结算',
                  style: TextStyle(
                    fontSize: AppDimens.fontM,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 购物车商品卡片
class _CartItemCard extends StatelessWidget {
  const _CartItemCard({required this.item});

  final CartItemEntity item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimens.spacingM),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 选择按钮
          InkWell(
            onTap: () {
              context
                  .read<CartBloc>()
                  .add(CartItemToggled(item.productId));
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 24, right: 4),
              child: Icon(
                item.selected
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                color: item.selected ? AppColors.primary : AppColors.textHint,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 4),
          // 商品图片
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimens.radiusS),
            child: AppNetworkImage(
              imageUrl: item.imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: AppDimens.spacingM),
          // 商品信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: AppDimens.fontS,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
                if (item.specs.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.specs,
                        style: const TextStyle(
                          fontSize: AppDimens.fontXS,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.price.toPriceString(),
                        style: const TextStyle(
                          fontSize: AppDimens.fontM,
                          fontWeight: FontWeight.bold,
                          color: AppColors.price,
                        ),
                      ),
                    ),
                    // 数量加减
                    _QuantitySelector(
                      quantity: item.quantity,
                      onDecrease: () {
                        context.read<CartBloc>().add(
                              CartQuantityUpdated(
                                item.productId,
                                item.quantity - 1,
                              ),
                            );
                      },
                      onIncrease: () {
                        context.read<CartBloc>().add(
                              CartQuantityUpdated(
                                item.productId,
                                item.quantity + 1,
                              ),
                            );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 数量选择器
class _QuantitySelector extends StatelessWidget {
  const _QuantitySelector({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: quantity > 1 ? onDecrease : null,
            child: SizedBox(
              width: 28,
              height: 28,
              child: Icon(
                Icons.remove,
                size: 16,
                color:
                    quantity > 1 ? AppColors.textPrimary : AppColors.textHint,
              ),
            ),
          ),
          Container(
            width: 32,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              border: Border.symmetric(
                vertical: BorderSide(color: AppColors.divider),
              ),
            ),
            child: Text(
              '$quantity',
              style: const TextStyle(
                fontSize: AppDimens.fontS,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          InkWell(
            onTap: onIncrease,
            child: const SizedBox(
              width: 28,
              height: 28,
              child: Icon(
                Icons.add,
                size: 16,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
