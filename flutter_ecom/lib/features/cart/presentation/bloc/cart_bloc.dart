import 'package:bloc/bloc.dart';
import '../../domain/usecases/add_to_cart_usecase.dart';
import '../../domain/usecases/get_cart_count_usecase.dart';
import '../../domain/usecases/get_cart_usecase.dart';
import '../../domain/usecases/remove_cart_item_usecase.dart';
import '../../domain/usecases/toggle_select_usecase.dart';
import '../../domain/usecases/update_quantity_usecase.dart';
import 'cart_event.dart';
import 'cart_state.dart';

/// 购物车 Bloc
///
/// 面试讲解点：
/// CartBloc 是全局单例，任何页面都可以通过 getIt<CartBloc>() 获取，
/// 实现跨页面状态同步。
///
/// 每次操作后都重新计算 totalCount 和 selectedTotalPrice，
/// 保证状态的一致性（单一数据源）。
class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc({
    required GetCartUseCase getCartUseCase,
    required AddToCartUseCase addToCartUseCase,
    required UpdateQuantityUseCase updateQuantityUseCase,
    required ToggleSelectUseCase toggleSelectUseCase,
    required ToggleSelectAllUseCase toggleSelectAllUseCase,
    required RemoveCartItemUseCase removeCartItemUseCase,
    required GetCartCountUseCase getCartCountUseCase,
  })  : _getCartUseCase = getCartUseCase,
        _addToCartUseCase = addToCartUseCase,
        _updateQuantityUseCase = updateQuantityUseCase,
        _toggleSelectUseCase = toggleSelectUseCase,
        _toggleSelectAllUseCase = toggleSelectAllUseCase,
        _removeCartItemUseCase = removeCartItemUseCase,
        _getCartCountUseCase = getCartCountUseCase,
        super(const CartState()) {
    on<CartLoaded>(_onLoaded);
    on<CartItemAdded>(_onItemAdded);
    on<CartQuantityUpdated>(_onQuantityUpdated);
    on<CartItemToggled>(_onItemToggled);
    on<CartSelectAllToggled>(_onSelectAllToggled);
    on<CartItemRemoved>(_onItemRemoved);
    on<CartCleared>(_onCleared);
  }

  final GetCartUseCase _getCartUseCase;
  final AddToCartUseCase _addToCartUseCase;
  final UpdateQuantityUseCase _updateQuantityUseCase;
  final ToggleSelectUseCase _toggleSelectUseCase;
  final ToggleSelectAllUseCase _toggleSelectAllUseCase;
  final RemoveCartItemUseCase _removeCartItemUseCase;
  final GetCartCountUseCase _getCartCountUseCase;

  /// 加载购物车
  Future<void> _onLoaded(CartLoaded event, Emitter<CartState> emit) async {
    await _refresh(emit);
  }

  /// 添加商品
  Future<void> _onItemAdded(
    CartItemAdded event,
    Emitter<CartState> emit,
  ) async {
    await _addToCartUseCase(event.item);
    await _refresh(emit);
  }

  /// 更新数量
  Future<void> _onQuantityUpdated(
    CartQuantityUpdated event,
    Emitter<CartState> emit,
  ) async {
    await _updateQuantityUseCase(event.productId, event.quantity);
    await _refresh(emit);
  }

  /// 切换选中
  Future<void> _onItemToggled(
    CartItemToggled event,
    Emitter<CartState> emit,
  ) async {
    await _toggleSelectUseCase(event.productId);
    await _refresh(emit);
  }

  /// 全选/取消全选
  Future<void> _onSelectAllToggled(
    CartSelectAllToggled event,
    Emitter<CartState> emit,
  ) async {
    await _toggleSelectAllUseCase(event.selected);
    await _refresh(emit);
  }

  /// 删除
  Future<void> _onItemRemoved(
    CartItemRemoved event,
    Emitter<CartState> emit,
  ) async {
    await _removeCartItemUseCase(event.productId);
    await _refresh(emit);
  }

  /// 清空
  Future<void> _onCleared(CartCleared event, Emitter<CartState> emit) async {
    // TODO: 调用 repository.clearCart()
    await _refresh(emit);
  }

  /// 刷新状态（每次操作后都从本地重新读取）
  Future<void> _refresh(Emitter<CartState> emit) async {
    final items = await _getCartUseCase();
    final totalCount = await _getCartCountUseCase();
    final selectedTotalPrice = items
        .where((item) => item.selected)
        .fold(0.0, (sum, item) => sum + item.subtotal);

    emit(state.copyWith(
      items: items,
      totalCount: totalCount,
      selectedTotalPrice: selectedTotalPrice,
    ));
  }
}
