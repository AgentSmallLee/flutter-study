import '../repositories/cart_repository.dart';

/// 清空购物车
///
/// 面试讲解点：
/// 为什么清空购物车是个单独的 UseCase 而不是直接调 Repository？
/// 1. 单一职责：每个用例对应一个业务操作，清晰明了
/// 2. 可扩展性：以后清空购物车前可能要加埋点、弹确认框逻辑等
/// 3. 可测试性：UseCase 可以单独做单元测试
class ClearCartUseCase {
  ClearCartUseCase(this._repository);

  final CartRepository _repository;

  Future<void> call() async {
    await _repository.clearCart();
  }
}
