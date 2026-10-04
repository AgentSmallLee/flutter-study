import '../../../../core/error/failures.dart';
import '../repositories/order_repository.dart';

/// 取消订单 UseCase
class CancelOrderUseCase {
  CancelOrderUseCase(this._repository);

  final OrderRepository _repository;

  Future<Result<void>> call(String orderId) {
    return _repository.cancelOrder(orderId);
  }
}
