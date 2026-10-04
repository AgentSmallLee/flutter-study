import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../domain/entities/order_entity.dart';

/// 订单状态标签
class OrderStatusTag extends StatelessWidget {
  const OrderStatusTag({
    super.key,
    required this.status,
    this.fontSize = AppDimens.fontS,
  });

  final OrderStatus status;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case OrderStatus.pendingPayment:
        color = AppColors.price;
        break;
      case OrderStatus.pendingShipment:
        color = AppColors.warning;
        break;
      case OrderStatus.pendingReceipt:
        color = AppColors.primary;
        break;
      case OrderStatus.completed:
        color = AppColors.textHint;
        break;
    }

    return Text(
      status.text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
        color: color,
      ),
    );
  }
}
