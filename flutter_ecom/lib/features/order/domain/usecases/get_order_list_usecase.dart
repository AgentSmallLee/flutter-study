import '../../../../core/error/failures.dart';
import '../entities/order_entity.dart';
import '../repositories/order_repository.dart';

/// 获取订单列表 UseCase
class GetOrderListUseCase {
  GetOrderListUseCase(this._repository);

  final OrderRepository _repository;

  Future<Result<List<OrderEntity>>> call({
    int? status,
    required int page,
    required int pageSize,
  }) {
    return _repository.getOrderList(
      status: status,
      page: page,
      pageSize: pageSize,
    );
  }
}
