import 'dart:async';
import '../entities/cart_item_entity.dart';

/// 购物车 Repository 接口
///
/// 面试讲解点：
/// 购物车是本地存储场景（Hive），但仍然使用 Repository 模式，
/// 好处是将来如果改成「购物车数据同步到服务端」，
/// 只需要改 Repository 实现，上层完全无感。
abstract class CartRepository {
  /// 获取购物车列表
  Future<List<CartItemEntity>> getCart();

  /// 添加商品到购物车
  Future<void> addToCart(CartItemEntity item);

  /// 更新商品数量
  Future<void> updateQuantity(int productId, int quantity);

  /// 切换选中状态
  Future<void> toggleSelected(int productId);

  /// 全选/取消全选
  Future<void> toggleSelectAll(bool selected);

  /// 移除购物车项
  Future<void> removeItem(int productId);

  /// 清空购物车
  Future<void> clearCart();

  /// 获取购物车商品总数
  Future<int> getCartCount();

  /// 获取选中商品的总价
  Future<double> getSelectedTotalPrice();
}
