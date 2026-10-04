import '../../domain/entities/product_entity.dart';

/// 商品数据模型
class ProductModel {
  ProductModel({
    required this.id,
    required this.name,
    this.description = '',
    required this.price,
    this.originalPrice,
    required this.imageUrl,
    this.images = const [],
    this.categoryId,
    this.stock = 0,
    this.salesCount = 0,
    this.rating = 0.0,
    this.specs = const [],
    this.tags = const [],
  });

  final int id;
  final String name;
  final String description;
  final double price;
  final double? originalPrice;
  final String imageUrl;
  final List<String> images;
  final int? categoryId;
  final int stock;
  final int salesCount;
  final double rating;
  final List<dynamic> specs;
  final List<dynamic> tags;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as int? ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      originalPrice: (json['originalPrice'] as num?)?.toDouble(),
      imageUrl: json['imageUrl']?.toString() ?? '',
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      categoryId: json['categoryId'] as int?,
      stock: json['stock'] as int? ?? 0,
      salesCount: json['salesCount'] as int? ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      specs: json['specs'] as List<dynamic>? ?? [],
      tags: json['tags'] as List<dynamic>? ?? [],
    );
  }

  ProductEntity toEntity() => ProductEntity(
        id: id,
        name: name,
        price: price,
        originalPrice: originalPrice,
        imageUrl: imageUrl,
        images: images,
        categoryId: categoryId,
        stock: stock,
        salesCount: salesCount,
        rating: rating,
        description: description,
        tags: tags.map((e) => e.toString()).toList(),
      );
}
