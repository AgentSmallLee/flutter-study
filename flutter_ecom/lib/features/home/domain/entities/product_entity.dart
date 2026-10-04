import 'package:equatable/equatable.dart';

/// 商品实体（Domain 层）
class ProductEntity extends Equatable {
  const ProductEntity({
    required this.id,
    required this.name,
    required this.price,
    this.originalPrice,
    required this.imageUrl,
    this.images = const [],
    this.categoryId,
    this.stock = 0,
    this.salesCount = 0,
    this.rating = 0.0,
    this.description = '',
    this.tags = const [],
  });

  final int id;
  final String name;
  final double price;
  final double? originalPrice;
  final String imageUrl;
  final List<String> images;
  final int? categoryId;
  final int stock;
  final int salesCount;
  final double rating;
  final String description;
  final List<String> tags;

  /// 是否有折扣
  bool get hasDiscount => originalPrice != null && originalPrice! > price;

  /// 折扣率（如 0.87 表示 87 折）
  double get discountRate {
    if (!hasDiscount) return 1.0;
    return price / originalPrice!;
  }

  @override
  List<Object?> get props => [
        id,
        name,
        price,
        originalPrice,
        imageUrl,
        categoryId,
        stock,
        salesCount,
        rating,
      ];
}
