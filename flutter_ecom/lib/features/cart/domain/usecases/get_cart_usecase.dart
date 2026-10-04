import '../entities/cart_item_entity.dart';
import '../repositories/cart_repository.dart';

/// 获取购物车列表用例
class GetCartUseCase {
  GetCartUseCase(this._repository);
  final CartRepository _repository;
  Future<List<CartItemEntity>> call() => _repository.getCart();
}
