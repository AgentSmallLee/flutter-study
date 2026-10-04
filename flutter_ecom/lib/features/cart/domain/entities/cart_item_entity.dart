import 'package:equatable/equatable.dart';

/// 购物车项实体
class CartItemEntity extends Equatable {
  const CartItemEntity({
    required this.productId,
    required this.productName,
    required this.price,
    required this.imageUrl,
    required this.quantity,
    this.selected = true,
    this.specs = '',
  });

  final int productId;
  final String productName;
  final double price;
  final String imageUrl;
  final int quantity;
  final bool selected;
  final String specs;

  /// 小计
  double get subtotal => price * quantity;

  /// 复制并更新
  CartItemEntity copyWith({
    int? productId,
    String? productName,
    double? price,
    String? imageUrl,
    int? quantity,
    bool? selected,
    String? specs,
  }) {
    return CartItemEntity(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      quantity: quantity ?? this.quantity,
      selected: selected ?? this.selected,
      specs: specs ?? this.specs,
    );
  }

  @override
  List<Object> get props => [
        productId,
        productName,
        price,
        imageUrl,
        quantity,
        selected,
        specs,
      ];
}
