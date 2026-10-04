import 'package:dartz/dartz.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/banner_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_datasource.dart';

/// 首页 Repository 实现
///
/// 面试讲解点：
/// Repository 模式的核心作用：
/// 1. 对上层（Domain / Presentation）隐藏数据来源细节
/// 2. 是数据的「汇集层」——可以从多个 DataSource 获取数据并做整合
/// 3. 错误处理集中：将各种异常统一转换为 Failure
///
/// 将来如果要加缓存逻辑（先读本地缓存，再刷新网络数据），
/// 只需修改这里，上层代码完全不需要改动。
class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl(this._remoteDataSource);

  final HomeRemoteDataSource _remoteDataSource;

  @override
  Future<Result<List<BannerEntity>>> getBanners() async {
    try {
      final models = await _remoteDataSource.getBanners();
      final entities = models.map((m) => m.toEntity()).toList();
      return Right(entities);
    } catch (e) {
      return Left(ErrorHandler.handleError(e));
    }
  }

  @override
  Future<Result<List<CategoryEntity>>> getCategories() async {
    try {
      final models = await _remoteDataSource.getCategories();
      final entities = models.map((m) => m.toEntity()).toList();
      return Right(entities);
    } catch (e) {
      return Left(ErrorHandler.handleError(e));
    }
  }

  @override
  Future<Result<List<ProductEntity>>> getRecommendProducts({
    required int page,
    required int pageSize,
  }) async {
    try {
      final paginationData = await _remoteDataSource.getRecommendProducts(
        page: page,
        pageSize: pageSize,
      );
      final entities = paginationData.list.map((m) => m.toEntity()).toList();
      return Right(entities);
    } catch (e) {
      return Left(ErrorHandler.handleError(e));
    }
  }
}
