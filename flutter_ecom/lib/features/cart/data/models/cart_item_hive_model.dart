import 'package:hive/hive.dart';

import '../../domain/entities/cart_item_entity.dart';

part 'cart_item_hive_model.g.dart';

/// 购物车 Hive 数据模型
///
/// 面试讲解点：
/// Hive 的 TypeAdapter 用于对象序列化/反序列化，
/// 可以通过 hive_generator 自动生成，也可以手写。
/// 这里手写 TypeAdapter（见 .g.dart 文件），不依赖代码生成。
///
/// TypeId 必须在 0-223 之间，且全局唯一。
class CartItemHiveModel extends HiveObject {
  CartItemHiveModel({
    required this.productId,
    required this.productName,
    required this.price,
    required this.imageUrl,
    required this.quantity,
    this.selected = true,
    this.specs = '',
  });

  int productId;
  String productName;
  double price;
  String imageUrl;
  int quantity;
  bool selected;
  String specs;

  /// Entity → Model
  factory CartItemHiveModel.fromEntity(CartItemEntity entity) {
    return CartItemHiveModel(
      productId: entity.productId,
      productName: entity.productName,
      price: entity.price,
      imageUrl: entity.imageUrl,
      quantity: entity.quantity,
      selected: entity.selected,
      specs: entity.specs,
    );
  }

  /// Model → Entity
  CartItemEntity toEntity() => CartItemEntity(
        productId: productId,
        productName: productName,
        price: price,
        imageUrl: imageUrl,
        quantity: quantity,
        selected: selected,
        specs: specs,
      );
}
