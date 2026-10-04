import '../repositories/cart_repository.dart';

/// 切换选中状态用例
class ToggleSelectUseCase {
  ToggleSelectUseCase(this._repository);
  final CartRepository _repository;
  Future<void> call(int productId) => _repository.toggleSelected(productId);
}

/// 全选用例
class ToggleSelectAllUseCase {
  ToggleSelectAllUseCase(this._repository);
  final CartRepository _repository;
  Future<void> call(bool selected) => _repository.toggleSelectAll(selected);
}
