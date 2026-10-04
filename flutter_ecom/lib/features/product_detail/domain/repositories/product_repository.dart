import '../../../../core/error/failures.dart';
import '../entities/product_detail_entity.dart';

/// 商品 Repository 抽象接口
///
/// 面试讲解点：
/// Domain 层只定义接口，不关心实现是来自网络还是本地缓存。
/// 上层（Bloc / UseCase）依赖抽象，不依赖具体实现，便于测试和替换。
abstract class ProductRepository {
  /// 获取商品详情
  Future<Result<ProductDetailEntity>> getProductDetail(int productId);
}
