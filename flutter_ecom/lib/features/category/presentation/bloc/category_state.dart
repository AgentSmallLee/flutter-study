import 'package:equatable/equatable.dart';
import '../../../home/domain/entities/category_entity.dart';

/// 分类页状态枚举
enum CategoryStatus { initial, loading, success, failure }

/// 分类页状态
class CategoryState extends Equatable {
  const CategoryState({
    this.status = CategoryStatus.initial,
    this.allCategories = const [],
    this.selectedRootId = 0,
  });

  final CategoryStatus status;

  /// 全部分类（包括一级和二级）
  final List<CategoryEntity> allCategories;

  /// 当前选中的一级分类 ID
  final int selectedRootId;

  /// 一级分类列表
  List<CategoryEntity> get rootCategories =>
      allCategories.where((c) => c.isRoot).toList();

  /// 当前选中分类的子分类列表
  List<CategoryEntity> get subCategories =>
      allCategories.where((c) => c.parentId == selectedRootId).toList();

  CategoryState copyWith({
    CategoryStatus? status,
    List<CategoryEntity>? allCategories,
    int? selectedRootId,
  }) {
    return CategoryState(
      status: status ?? this.status,
      allCategories: allCategories ?? this.allCategories,
      selectedRootId: selectedRootId ?? this.selectedRootId,
    );
  }

  @override
  List<Object> get props => [status, allCategories, selectedRootId];
}
