import '../../domain/entities/product_detail_entity.dart';

/// 商品详情规格组数据模型
class SpecGroupModel {
  SpecGroupModel({
    required this.name,
    required this.values,
  });

  final String name;
  final List<String> values;

  factory SpecGroupModel.fromJson(Map<String, dynamic> json) {
    return SpecGroupModel(
      name: json['name']?.toString() ?? '',
      values: (json['values'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  SpecGroupEntity toEntity() => SpecGroupEntity(
        name: name,
        values: values,
      );
}

/// 商品详情数据模型
class ProductDetailModel {
  ProductDetailModel({
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
    this.reviewCount = 0,
    this.specs = const [],
    this.tags = const [],
    this.detailImages = const [],
    this.shipping = '',
    this.service = const [],
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
  final int reviewCount;
  final List<SpecGroupModel> specs;
  final List<dynamic> tags;
  final List<String> detailImages;
  final String shipping;
  final List<dynamic> service;

  factory ProductDetailModel.fromJson(Map<String, dynamic> json) {
    final specsJson = json['specs'] as List<dynamic>? ?? [];
    final specs = specsJson
        .map((e) => SpecGroupModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return ProductDetailModel(
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
      reviewCount: json['reviewCount'] as int? ?? 0,
      specs: specs,
      tags: json['tags'] as List<dynamic>? ?? [],
      detailImages: (json['detailImages'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      shipping: json['shipping']?.toString() ?? '',
      service: json['service'] as List<dynamic>? ?? [],
    );
  }

  ProductDetailEntity toEntity() => ProductDetailEntity(
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
        reviewCount: reviewCount,
        description: description,
        specs: specs.map((e) => e.toEntity()).toList(),
        tags: tags.map((e) => e.toString()).toList(),
        detailImages: detailImages,
        shipping: shipping,
        service: service.map((e) => e.toString()).toList(),
      );
}
