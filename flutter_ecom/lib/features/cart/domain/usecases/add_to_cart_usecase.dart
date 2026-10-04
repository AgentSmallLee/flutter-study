import '../entities/cart_item_entity.dart';
import '../repositories/cart_repository.dart';

/// 添加到购物车用例
class AddToCartUseCase {
  AddToCartUseCase(this._repository);
  final CartRepository _repository;
  Future<void> call(CartItemEntity item) => _repository.addToCart(item);
}
