import 'dart:async';
import '../../../../core/error/failures.dart';
import '../entities/banner_entity.dart';
import '../entities/category_entity.dart';
import '../entities/product_entity.dart';

/// 首页 Repository 接口（Domain 层）
///
/// 面试讲解点：
/// Domain 层只定义 Repository 的抽象接口，
/// 具体实现在 Data 层（HomeRepositoryImpl）。
/// 这样上层（Presentation / UseCase）只依赖抽象，
/// 不依赖具体的数据源（API / 本地数据库），
/// 符合依赖倒置原则（DIP）。
abstract class HomeRepository {
  /// 获取首页 Banner 列表
  Future<Result<List<BannerEntity>>> getBanners();

  /// 获取首页分类列表
  Future<Result<List<CategoryEntity>>> getCategories();

  /// 获取推荐商品列表（分页）
  Future<Result<List<ProductEntity>>> getRecommendProducts({
    required int page,
    required int pageSize,
  });
}
