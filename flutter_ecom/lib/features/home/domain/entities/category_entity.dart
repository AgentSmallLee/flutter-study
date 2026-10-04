import 'package:equatable/equatable.dart';

/// 分类实体（Domain 层）
class CategoryEntity extends Equatable {
  const CategoryEntity({
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

  /// 是否为一级分类
  bool get isRoot => parentId == 0;

  @override
  List<Object> get props => [id, name, icon, parentId, sort];
}
