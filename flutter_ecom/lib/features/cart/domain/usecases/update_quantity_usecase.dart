import '../repositories/cart_repository.dart';

/// 更新购物车商品数量用例
class UpdateQuantityUseCase {
  UpdateQuantityUseCase(this._repository);
  final CartRepository _repository;
  Future<void> call(int productId, int quantity) =>
      _repository.updateQuantity(productId, quantity);
}
