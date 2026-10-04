import 'package:equatable/equatable.dart';

/// 订单项实体
class OrderItemEntity extends Equatable {
  const OrderItemEntity({
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.price,
    required this.quantity,
    required this.specs,
  });

  final int productId;
  final String productName;
  final String imageUrl;
  final double price;
  final int quantity;
  final String specs;

  @override
  List<Object> get props => [
        productId,
        productName,
        imageUrl,
        price,
        quantity,
        specs,
      ];
}
