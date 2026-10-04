import '../repositories/cart_repository.dart';

/// 获取购物车数量用例
class GetCartCountUseCase {
  GetCartCountUseCase(this._repository);
  final CartRepository _repository;
  Future<int> call() => _repository.getCartCount();
}
