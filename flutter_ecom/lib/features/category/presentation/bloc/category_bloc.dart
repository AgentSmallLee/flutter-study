import 'package:bloc/bloc.dart';
import '../../../home/domain/usecases/get_categories_usecase.dart';
import 'category_event.dart';
import 'category_state.dart';

/// 分类页 Bloc
///
/// 面试讲解点：
/// 分类数据一次性全部加载（数据量小），然后在 Bloc 内做父子分组。
/// 选中一级分类时，直接从已加载的全量数据中过滤出子分类，
/// 不需要再发网络请求，响应速度快。
class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  CategoryBloc(this._getCategoriesUseCase)
      : super(const CategoryState()) {
    on<CategoryLoaded>(_onLoaded);
    on<CategorySelected>(_onSelected);
  }

  final GetCategoriesUseCase _getCategoriesUseCase;

  Future<void> _onLoaded(
    CategoryLoaded event,
    Emitter<CategoryState> emit,
  ) async {
    emit(state.copyWith(status: CategoryStatus.loading));
    final result = await _getCategoriesUseCase();
    result.fold(
      (failure) => emit(state.copyWith(status: CategoryStatus.failure)),
      (allCategories) {
        final rootCategories =
            allCategories.where((c) => c.isRoot).toList();
        final selectedId =
            rootCategories.isNotEmpty ? rootCategories.first.id : 0;
        emit(state.copyWith(
          status: CategoryStatus.success,
          allCategories: allCategories,
          selectedRootId: selectedId,
        ));
      },
    );
  }

  void _onSelected(
    CategorySelected event,
    Emitter<CategoryState> emit,
  ) {
    emit(state.copyWith(selectedRootId: event.categoryId));
  }
}
