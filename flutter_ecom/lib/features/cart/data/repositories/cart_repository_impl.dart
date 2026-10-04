import '../../domain/entities/cart_item_entity.dart';
import '../../domain/repositories/cart_repository.dart';
import '../datasources/cart_local_datasource.dart';
import '../models/cart_item_hive_model.dart';

/// 购物车 Repository 实现
class CartRepositoryImpl implements CartRepository {
  CartRepositoryImpl(this._localDataSource);

  final CartLocalDataSource _localDataSource;

  @override
  Future<List<CartItemEntity>> getCart() async {
    final models = _localDataSource.getAll();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> addToCart(CartItemEntity item) async {
    final existing = _localDataSource.getByProductId(item.productId);
    if (existing != null) {
      // 已存在则数量相加
      final updated = existing
        ..quantity = existing.quantity + item.quantity;
      await _localDataSource.put(updated);
    } else {
      // 不存在则新增
      await _localDataSource.put(CartItemHiveModel.fromEntity(item));
    }
  }

  @override
  Future<void> updateQuantity(int productId, int quantity) async {
    final item = _localDataSource.getByProductId(productId);
    if (item != null) {
      if (quantity <= 0) {
        // 数量为 0 时删除
        await _localDataSource.remove(productId);
      } else {
        item.quantity = quantity;
        await _localDataSource.put(item);
      }
    }
  }

  @override
  Future<void> toggleSelected(int productId) async {
    final item = _localDataSource.getByProductId(productId);
    if (item != null) {
      item.selected = !item.selected;
      await _localDataSource.put(item);
    }
  }

  @override
  Future<void> toggleSelectAll(bool selected) async {
    final items = _localDataSource.getAll();
    for (final item in items) {
      item.selected = selected;
      await _localDataSource.put(item);
    }
  }

  @override
  Future<void> removeItem(int productId) async {
    await _localDataSource.remove(productId);
  }

  @override
  Future<void> clearCart() async {
    await _localDataSource.clear();
  }

  @override
  Future<int> getCartCount() async {
    return _localDataSource.getCount();
  }

  @override
  Future<double> getSelectedTotalPrice() async {
    final items = _localDataSource.getAll();
    double total = 0;
    for (final item in items) {
      if (item.selected) {
        total += item.price * item.quantity;
      }
    }
    return total;
  }
}
