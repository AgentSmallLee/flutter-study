import 'package:dartz/dartz.dart';

import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/product_detail_entity.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_remote_datasource.dart';

/// 商品 Repository 实现
class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl(this._remoteDataSource);

  final ProductRemoteDataSource _remoteDataSource;

  @override
  Future<Result<ProductDetailEntity>> getProductDetail(int productId) async {
    try {
      final model = await _remoteDataSource.getProductDetail(productId);
      return Right(model.toEntity());
    } catch (e) {
      return Left(ErrorHandler.handleError(e));
    }
  }
}
