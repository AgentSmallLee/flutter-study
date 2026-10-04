import 'package:equatable/equatable.dart';
import '../../domain/entities/cart_item_entity.dart';

/// 购物车状态
///
/// 面试讲解点：
/// CartBloc 是全局单例 Bloc（在 getIt 中以 singleton 注册），
/// 因为购物车状态需要在多个页面共享（底部导航徽标、商品详情、购物车页）。
///
/// 购物车数据存在本地，加载速度很快，
/// 所以状态设计得比较简单，没有 Loading/Error 等细分状态。
class CartState extends Equatable {
  const CartState({
    this.items = const [],
    this.totalCount = 0,
    this.selectedTotalPrice = 0.0,
  });

  final List<CartItemEntity> items;
  final int totalCount;
  final double selectedTotalPrice;

  /// 是否全选
  bool get isAllSelected =>
      items.isNotEmpty && items.every((item) => item.selected);

  /// 选中商品数量
  int get selectedCount =>
      items.where((item) => item.selected).fold(0, (sum, e) => sum + e.quantity);

  CartState copyWith({
    List<CartItemEntity>? items,
    int? totalCount,
    double? selectedTotalPrice,
  }) {
    return CartState(
      items: items ?? this.items,
      totalCount: totalCount ?? this.totalCount,
      selectedTotalPrice: selectedTotalPrice ?? this.selectedTotalPrice,
    );
  }

  @override
  List<Object> get props => [items, totalCount, selectedTotalPrice];
}
