import 'package:dartz/dartz.dart';

import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/repositories/order_repository.dart';
import '../datasources/order_remote_datasource.dart';

/// 订单 Repository 实现
class OrderRepositoryImpl implements OrderRepository {
  OrderRepositoryImpl(this._remoteDataSource);

  final OrderRemoteDataSource _remoteDataSource;

  @override
  Future<Result<List<OrderEntity>>> getOrderList({
    int? status,
    required int page,
    required int pageSize,
  }) async {
    try {
      final models = await _remoteDataSource.getOrderList(
        status: status,
        page: page,
        pageSize: pageSize,
      );
      return Right(models.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Left(ErrorHandler.handleError(e));
    }
  }

  @override
  Future<Result<OrderEntity>> getOrderDetail(String orderId) async {
    try {
      final model = await _remoteDataSource.getOrderDetail(orderId);
      return Right(model.toEntity());
    } catch (e) {
      return Left(ErrorHandler.handleError(e));
    }
  }

  @override
  Future<Result<void>> cancelOrder(String orderId) async {
    try {
      await _remoteDataSource.cancelOrder(orderId);
      return const Right(null);
    } catch (e) {
      return Left(ErrorHandler.handleError(e));
    }
  }

  @override
  Future<Result<void>> confirmReceipt(String orderId) async {
    try {
      await _remoteDataSource.confirmReceipt(orderId);
      return const Right(null);
    } catch (e) {
      return Left(ErrorHandler.handleError(e));
    }
  }
}
