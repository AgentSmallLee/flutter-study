import '../../domain/entities/order_entity.dart';
import 'order_item_model.dart';
import 'order_address_model.dart';
import 'logistics_model.dart';

/// 订单数据模型
class OrderModel {
  OrderModel({
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
  final List<OrderItemModel> items;
  final OrderAddressModel address;
  final LogisticsModel? logistics;

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List? ?? [];
    return OrderModel(
      id: json['id'] as String,
      orderNo: json['orderNo'] as String,
      status: json['status'] as int,
      statusText: json['statusText'] as String,
      totalAmount: (json['totalAmount'] as num).toDouble(),
      freight: (json['freight'] as num).toDouble(),
      discount: (json['discount'] as num).toDouble(),
      payAmount: (json['payAmount'] as num).toDouble(),
      createTime: json['createTime'] as String,
      items: itemsList
          .map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      address: OrderAddressModel.fromJson(
          json['address'] as Map<String, dynamic>),
      logistics: json['logistics'] != null
          ? LogisticsModel.fromJson(
              json['logistics'] as Map<String, dynamic>)
          : null,
    );
  }

  OrderEntity toEntity() {
    return OrderEntity(
      id: id,
      orderNo: orderNo,
      status: status,
      statusText: statusText,
      totalAmount: totalAmount,
      freight: freight,
      discount: discount,
      payAmount: payAmount,
      createTime: createTime,
      items: items.map((e) => e.toEntity()).toList(),
      address: address.toEntity(),
      logistics: logistics?.toEntity(),
    );
  }
}
