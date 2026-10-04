import '../../../../core/error/failures.dart';
import '../entities/category_entity.dart';
import '../repositories/home_repository.dart';

/// 获取分类列表用例
class GetCategoriesUseCase {
  GetCategoriesUseCase(this._repository);

  final HomeRepository _repository;

  Future<Result<List<CategoryEntity>>> call() {
    return _repository.getCategories();
  }
}
