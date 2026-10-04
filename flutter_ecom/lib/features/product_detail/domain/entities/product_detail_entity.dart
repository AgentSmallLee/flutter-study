import 'package:equatable/equatable.dart';

/// 规格分组实体
class SpecGroupEntity extends Equatable {
  const SpecGroupEntity({
    required this.name,
    required this.values,
  });

  final String name;
  final List<String> values;

  @override
  List<Object> get props => [name, values];
}

/// 商品详情实体（Domain 层）
///
/// 面试讲解点：
/// 为什么商品列表和详情用两个不同的 Entity？
/// 1. 职责单一：列表页只需要展示用的精简字段，详情页需要完整字段
/// 2. 性能：列表接口返回数据量小，加载更快
/// 3. 解耦：两端接口独立演进，互不影响
class ProductDetailEntity extends Equatable {
  const ProductDetailEntity({
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
    this.reviewCount = 0,
    this.description = '',
    this.specs = const [],
    this.tags = const [],
    this.detailImages = const [],
    this.shipping = '',
    this.service = const [],
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
  final int reviewCount;
  final String description;
  final List<SpecGroupEntity> specs;
  final List<String> tags;
  final List<String> detailImages;
  final String shipping;
  final List<String> service;

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
        images,
        categoryId,
        stock,
        salesCount,
        rating,
        reviewCount,
        description,
        specs,
        tags,
        detailImages,
        shipping,
        service,
      ];
}
