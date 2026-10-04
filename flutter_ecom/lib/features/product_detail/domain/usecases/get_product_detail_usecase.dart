import '../../../../core/error/failures.dart';
import '../entities/product_detail_entity.dart';
import '../repositories/product_repository.dart';

/// 获取商品详情 UseCase
///
/// 面试讲解点：
/// UseCase 封装单一业务逻辑，Bloc 只负责状态管理，不直接操作 Repository。
/// 好处：业务逻辑集中，便于测试和复用。
class GetProductDetailUseCase {
  GetProductDetailUseCase(this._repository);

  final ProductRepository _repository;

  Future<Result<ProductDetailEntity>> call(int productId) {
    return _repository.getProductDetail(productId);
  }
}
