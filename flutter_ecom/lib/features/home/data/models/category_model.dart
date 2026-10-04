import '../../domain/entities/category_entity.dart';

/// 分类数据模型
class CategoryModel {
  CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.parentId,
    required this.sort,
  });

  final int id;
  final String name;
  final String icon;
  final int parentId;
  final int sort;

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as int? ?? 0,
      name: json['name']?.toString() ?? '',
      icon: json['icon']?.toString() ?? '',
      parentId: json['parentId'] as int? ?? 0,
      sort: json['sort'] as int? ?? 0,
    );
  }

  CategoryEntity toEntity() => CategoryEntity(
        id: id,
        name: name,
        icon: icon,
        parentId: parentId,
        sort: sort,
      );
}
