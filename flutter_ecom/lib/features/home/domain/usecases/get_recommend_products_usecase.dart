import '../../../../core/error/failures.dart';
import '../entities/product_entity.dart';
import '../repositories/home_repository.dart';

/// 获取推荐商品列表用例（分页）
class GetRecommendProductsUseCase {
  GetRecommendProductsUseCase(this._repository);

  final HomeRepository _repository;

  Future<Result<List<ProductEntity>>> call({
    required int page,
    required int pageSize,
  }) {
    return _repository.getRecommendProducts(
      page: page,
      pageSize: pageSize,
    );
  }
}
