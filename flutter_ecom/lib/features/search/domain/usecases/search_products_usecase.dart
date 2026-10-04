import '../../../../core/error/failures.dart';
import '../../../../features/home/domain/entities/product_entity.dart';
import '../repositories/search_repository.dart';

/// 搜索商品 UseCase
class SearchProductsUseCase {
  SearchProductsUseCase(this._repository);
  final SearchRepository _repository;

  Future<Result<List<ProductEntity>>> call({
    required String keyword,
    required int page,
    required int pageSize,
  }) {
    return _repository.searchProducts(
      keyword: keyword,
      page: page,
      pageSize: pageSize,
    );
  }
}
