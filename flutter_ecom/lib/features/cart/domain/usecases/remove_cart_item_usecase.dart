import '../repositories/cart_repository.dart';

/// 移除购物车项用例
class RemoveCartItemUseCase {
  RemoveCartItemUseCase(this._repository);
  final CartRepository _repository;
  Future<void> call(int productId) => _repository.removeItem(productId);
}
