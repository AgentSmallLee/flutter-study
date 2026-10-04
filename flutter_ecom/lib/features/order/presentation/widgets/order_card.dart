import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/extensions/num_extensions.dart';
import '../../../../core/widgets/common/cache_network_image.dart';
import '../../domain/entities/order_entity.dart';
import 'order_status_tag.dart';

/// 订单卡片
///
/// 面试讲解点：
/// 订单卡片是典型的「状态驱动 UI」组件：
/// 顶部状态标签颜色、底部操作按钮，都根据订单状态动态变化。
class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.order,
    this.onCancel,
    this.onPay,
    this.onConfirm,
    this.onViewLogistics,
  });

  final OrderEntity order;
  final VoidCallback? onCancel;
  final VoidCallback? onPay;
  final VoidCallback? onConfirm;
  final VoidCallback? onViewLogistics;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.spacingM),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
      ),
      child: InkWell(
        onTap: () => context.push('/order/${order.id}'),
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        child: Column(
          children: [
            _buildHeader(),
            const Divider(height: 1, color: AppColors.divider),
            _buildProducts(),
            const Divider(height: 1, color: AppColors.divider),
            _buildFooter(),
            const SizedBox(height: AppDimens.spacingM),
          ],
        ),
      ),
    );
  }

  // 顶部：店铺/订单号 + 状态
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppDimens.spacingM),
      child: Row(
        children: [
          const Icon(Icons.store_outlined,
              size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          const Text(
            '官方旗舰店',
            style: TextStyle(
              fontSize: AppDimens.fontS,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          OrderStatusTag(status: order.orderStatus),
        ],
      ),
    );
  }

  // 中间：商品列表
  Widget _buildProducts() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppDimens.spacingM),
      itemCount: order.items.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: AppDimens.spacingM),
      itemBuilder: (context, index) {
        final item = order.items[index];
        return Row(
          children: [
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
            Expanded(
              child: SizedBox(
                height: 80,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    Row(
                      children: [
                        Text(
                          item.specs,
                          style: const TextStyle(
                            fontSize: AppDimens.fontXS,
                            color: AppColors.textHint,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          item.price.toPriceString(),
                          style: const TextStyle(
                            fontSize: AppDimens.fontS,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          ' x${item.quantity}',
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
            ),
          ],
        );
      },
    );
  }

  // 底部：合计 + 操作按钮
  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.spacingM),
      child: Column(
        children: [
          const SizedBox(height: AppDimens.spacingM),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '共${order.totalQuantity}件  合计 ',
                style: const TextStyle(
                  fontSize: AppDimens.fontS,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                order.payAmount.toPriceString(),
                style: const TextStyle(
                  fontSize: AppDimens.fontM,
                  fontWeight: FontWeight.bold,
                  color: AppColors.price,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.spacingM),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: _buildActionButtons(),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActionButtons() {
    switch (order.orderStatus) {
      case OrderStatus.pendingPayment:
        return [
          _buildOutlineButton('取消订单', onCancel),
          const SizedBox(width: AppDimens.spacingS),
          _buildPrimaryButton('去支付', onPay),
        ];
      case OrderStatus.pendingShipment:
        return [
          _buildOutlineButton('取消订单', onCancel),
          const SizedBox(width: AppDimens.spacingS),
          _buildOutlineButton('提醒发货', null),
        ];
      case OrderStatus.pendingReceipt:
        return [
          _buildOutlineButton('查看物流', onViewLogistics),
          const SizedBox(width: AppDimens.spacingS),
          _buildPrimaryButton('确认收货', onConfirm),
        ];
      case OrderStatus.completed:
        return [
          _buildOutlineButton('申请售后', null),
          const SizedBox(width: AppDimens.spacingS),
          _buildOutlineButton('再次购买', null),
        ];
    }
  }

  Widget _buildOutlineButton(String text, VoidCallback? onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 30),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.spacingM,
        ),
        side: const BorderSide(color: AppColors.divider),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusFull),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: AppDimens.fontXS,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(String text, VoidCallback? onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.price,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 30),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.spacingM,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusFull),
        ),
        elevation: 0,
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: AppDimens.fontXS,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
