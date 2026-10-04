import '../../../../core/error/failures.dart';
import '../../../home/domain/entities/product_entity.dart';

/// 搜索 Repository 抽象接口
abstract class SearchRepository {
  /// 搜索商品
  Future<Result<List<ProductEntity>>> searchProducts({
    required String keyword,
    required int page,
    required int pageSize,
  });

  /// 获取搜索历史
  Future<List<String>> getSearchHistory();

  /// 保存搜索历史
  Future<void> saveSearchHistory(String keyword);

  /// 清空搜索历史
  Future<void> clearSearchHistory();

  /// 获取热门搜索
  Future<List<String>> getHotKeywords();
}
