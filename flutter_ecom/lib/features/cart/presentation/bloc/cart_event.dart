import 'package:equatable/equatable.dart';
import '../../domain/entities/cart_item_entity.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object> get props => [];
}

/// 加载购物车
class CartLoaded extends CartEvent {
  const CartLoaded();
}

/// 添加到购物车
class CartItemAdded extends CartEvent {
  const CartItemAdded(this.item);
  final CartItemEntity item;

  @override
  List<Object> get props => [item];
}

/// 更新数量
class CartQuantityUpdated extends CartEvent {
  const CartQuantityUpdated(this.productId, this.quantity);
  final int productId;
  final int quantity;

  @override
  List<Object> get props => [productId, quantity];
}

/// 切换选中
class CartItemToggled extends CartEvent {
  const CartItemToggled(this.productId);
  final int productId;

  @override
  List<Object> get props => [productId];
}

/// 全选/取消全选
class CartSelectAllToggled extends CartEvent {
  const CartSelectAllToggled(this.selected);
  final bool selected;

  @override
  List<Object> get props => [selected];
}

/// 删除购物车项
class CartItemRemoved extends CartEvent {
  const CartItemRemoved(this.productId);
  final int productId;

  @override
  List<Object> get props => [productId];
}

/// 清空购物车
class CartCleared extends CartEvent {
  const CartCleared();
}
