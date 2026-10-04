import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/di/service_locator.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/bloc/cart_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// 商品详情底部操作栏
class ProductBottomBar extends StatelessWidget {
  const ProductBottomBar({
    super.key,
    required this.onAddToCart,
    required this.onBuyNow,
  });

  final VoidCallback onAddToCart;
  final VoidCallback onBuyNow;

  @override
  Widget build(BuildContext context) {
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
            // 客服
            _buildIconItem(Icons.headset_mic_outlined, '客服', () {}),
            const SizedBox(width: AppDimens.spacingL),
            // 购物车（带徽标）
            _buildCartIcon(),
            const SizedBox(width: AppDimens.spacingL),
            // 店铺
            _buildIconItem(Icons.storefront_outlined, '店铺', () {}),
            const SizedBox(width: AppDimens.spacingL),
            // 加入购物车
            Expanded(
              child: SizedBox(
                height: AppDimens.buttonHeight,
                child: ElevatedButton(
                  onPressed: onAddToCart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB800),
                    foregroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(AppDimens.radiusFull),
                      ),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    '加入购物车',
                    style: TextStyle(
                      fontSize: AppDimens.fontM,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            // 立即购买
            Expanded(
              child: SizedBox(
                height: AppDimens.buttonHeight,
                child: ElevatedButton(
                  onPressed: onBuyNow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.horizontal(
                        right: Radius.circular(AppDimens.radiusFull),
                      ),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    '立即购买',
                    style: TextStyle(
                      fontSize: AppDimens.fontM,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconItem(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.radiusS),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: AppColors.textSecondary),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: AppDimens.fontXS,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartIcon() {
    return BlocBuilder<CartBloc, CartState>(
      bloc: getIt<CartBloc>(),
      builder: (context, state) {
        return InkWell(
          onTap: () {
            // TODO: 跳转到购物车 Tab
          },
          borderRadius: BorderRadius.circular(AppDimens.radiusS),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.shopping_cart_outlined,
                      size: 22, color: AppColors.textSecondary),
                  SizedBox(height: 2),
                  Text(
                    '购物车',
                    style: TextStyle(
                      fontSize: AppDimens.fontXS,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              if (state.totalCount > 0)
                Positioned(
                  right: -6,
                  top: -4,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    constraints: const BoxConstraints(minWidth: 16),
                    decoration: BoxDecoration(
                      color: AppColors.price,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      state.totalCount > 99
                          ? '99+'
                          : '${state.totalCount}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
