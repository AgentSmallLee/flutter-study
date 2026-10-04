import '../../../../core/error/failures.dart';
import '../entities/order_entity.dart';
import '../repositories/order_repository.dart';

/// 获取订单详情 UseCase
class GetOrderDetailUseCase {
  GetOrderDetailUseCase(this._repository);

  final OrderRepository _repository;

  Future<Result<OrderEntity>> call(String orderId) {
    return _repository.getOrderDetail(orderId);
  }
}
