import 'package:hive/hive.dart';
import '../models/cart_item_hive_model.dart';

/// 购物车本地数据源（Hive）
///
/// 面试讲解点：
/// 为什么选 Hive 而不是 shared_preferences 存购物车？
/// 1. 购物车是列表结构，Hive 天然支持对象存储，不用自己序列化/反序列化 JSON
/// 2. 性能更好：Hive 是纯 Dart 实现的 NoSQL，读写快，不需要异步通道
/// 3. 支持开箱即用的增删改查操作
/// 4. 支持 TypeAdapter，类型安全
class CartLocalDataSource {
  CartLocalDataSource(this._box);

  final Box<CartItemHiveModel> _box;

  /// 获取所有购物车项
  List<CartItemHiveModel> getAll() {
    return _box.values.toList();
  }

  /// 根据商品 ID 获取
  CartItemHiveModel? getByProductId(int productId) {
    return _box.get(productId);
  }

  /// 添加或更新购物车项
  Future<void> put(CartItemHiveModel item) async {
    // 用 productId 作为 key，保证同一商品只有一条记录
    await _box.put(item.productId, item);
  }

  /// 删除指定商品
  Future<void> remove(int productId) async {
    await _box.delete(productId);
  }

  /// 清空购物车
  Future<void> clear() async {
    await _box.clear();
  }

  /// 购物车商品总数量
  int getCount() {
    return _box.values.fold(0, (sum, item) => sum + item.quantity);
  }
}
