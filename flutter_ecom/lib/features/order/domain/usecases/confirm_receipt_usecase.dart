import '../../../../core/error/failures.dart';
import '../repositories/order_repository.dart';

/// 确认收货 UseCase
class ConfirmReceiptUseCase {
  ConfirmReceiptUseCase(this._repository);

  final OrderRepository _repository;

  Future<Result<void>> call(String orderId) {
    return _repository.confirmReceipt(orderId);
  }
}
