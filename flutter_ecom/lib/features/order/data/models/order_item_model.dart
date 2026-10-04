import '../../domain/entities/order_item_entity.dart';

/// 订单项数据模型
class OrderItemModel {
  OrderItemModel({
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

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      productId: json['productId'] as int,
      productName: json['productName'] as String,
      imageUrl: json['imageUrl'] as String,
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] as int,
      specs: json['specs'] as String,
    );
  }

  OrderItemEntity toEntity() {
    return OrderItemEntity(
      productId: productId,
      productName: productName,
      imageUrl: imageUrl,
      price: price,
      quantity: quantity,
      specs: specs,
    );
  }
}
