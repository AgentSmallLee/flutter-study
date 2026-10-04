import 'package:equatable/equatable.dart';

/// 分类页事件
abstract class CategoryEvent extends Equatable {
  const CategoryEvent();

  @override
  List<Object> get props => [];
}

/// 加载分类数据
class CategoryLoaded extends CategoryEvent {
  const CategoryLoaded();
}

/// 选中一级分类
class CategorySelected extends CategoryEvent {
  const CategorySelected(this.categoryId);

  final int categoryId;

  @override
  List<Object> get props => [categoryId];
}
