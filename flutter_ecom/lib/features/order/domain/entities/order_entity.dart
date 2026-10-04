import 'package:equatable/equatable.dart';
import 'order_item_entity.dart';
import 'order_address_entity.dart';
import 'logistics_entity.dart';

/// 订单状态
enum OrderStatus {
  pendingPayment(0, '待付款'),
  pendingShipment(1, '待发货'),
  pendingReceipt(2, '待收货'),
  completed(3, '已完成');

  const OrderStatus(this.code, this.text);

  final int code;
  final String text;

  static OrderStatus fromCode(int code) {
    return OrderStatus.values.firstWhere(
      (e) => e.code == code,
      orElse: () => OrderStatus.completed,
    );
  }
}

/// 订单实体（Domain 层）
class OrderEntity extends Equatable {
  const OrderEntity({
    required this.id,
    required this.orderNo,
    required this.status,
    required this.statusText,
    required this.totalAmount,
    required this.freight,
    required this.discount,
    required this.payAmount,
    required this.createTime,
    required this.items,
    required this.address,
    this.logistics,
  });

  final String id;
  final String orderNo;
  final int status;
  final String statusText;
  final double totalAmount;
  final double freight;
  final double discount;
  final double payAmount;
  final String createTime;
  final List<OrderItemEntity> items;
  final OrderAddressEntity address;
  final LogisticsEntity? logistics;

  /// 订单状态枚举
  OrderStatus get orderStatus => OrderStatus.fromCode(status);

  /// 商品总数
  int get totalQuantity =>
      items.fold(0, (sum, item) => sum + item.quantity);

  @override
  List<Object?> get props => [
        id,
        orderNo,
        status,
        statusText,
        totalAmount,
        freight,
        discount,
        payAmount,
        createTime,
        items,
        address,
        logistics,
      ];
}
