import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/cancel_order_usecase.dart';
import '../../domain/usecases/confirm_receipt_usecase.dart';
import '../../domain/usecases/get_order_detail_usecase.dart';
import 'order_detail_event.dart';
import 'order_detail_state.dart';

/// 订单详情 Bloc
///
/// 面试讲解点：
/// 订单详情使用多态状态类：initial / loading / success / failure / actionLoading。
/// actionLoading 用于取消订单、确认收货等操作的 loading 态，
/// 此时页面仍展示订单数据，只是操作按钮置灰。
class OrderDetailBloc extends Bloc<OrderDetailEvent, OrderDetailState> {
  OrderDetailBloc({
    required GetOrderDetailUseCase getOrderDetailUseCase,
    required CancelOrderUseCase cancelOrderUseCase,
    required ConfirmReceiptUseCase confirmReceiptUseCase,
  })  : _getOrderDetailUseCase = getOrderDetailUseCase,
        _cancelOrderUseCase = cancelOrderUseCase,
        _confirmReceiptUseCase = confirmReceiptUseCase,
        super(const OrderDetailInitial()) {
    on<OrderDetailStarted>(_onStarted);
    on<OrderDetailCancelled>(_onCancelled);
    on<OrderDetailConfirmed>(_onConfirmed);
  }

  final GetOrderDetailUseCase _getOrderDetailUseCase;
  final CancelOrderUseCase _cancelOrderUseCase;
  final ConfirmReceiptUseCase _confirmReceiptUseCase;

  String _orderId = '';

  /// 加载订单详情
  Future<void> _onStarted(
    OrderDetailStarted event,
    Emitter<OrderDetailState> emit,
  ) async {
    _orderId = event.orderId;
    emit(const OrderDetailLoading());

    final result = await _getOrderDetailUseCase(event.orderId);

    result.fold(
      (failure) => emit(OrderDetailFailure(failure.message)),
      (order) => emit(OrderDetailSuccess(order)),
    );
  }

  /// 取消订单
  Future<void> _onCancelled(
    OrderDetailCancelled event,
    Emitter<OrderDetailState> emit,
  ) async {
    if (state is! OrderDetailSuccess) return;
    final currentOrder = (state as OrderDetailSuccess).order;
    emit(OrderDetailActionLoading(currentOrder));

    final result = await _cancelOrderUseCase(_orderId);

    result.fold(
      (failure) => emit(OrderDetailFailure(failure.message)),
      // Mock 环境下重新加载详情（数据不变，仅模拟流程）
      (_) => add(OrderDetailStarted(_orderId)),
    );
  }

  /// 确认收货
  Future<void> _onConfirmed(
    OrderDetailConfirmed event,
    Emitter<OrderDetailState> emit,
  ) async {
    if (state is! OrderDetailSuccess) return;
    final currentOrder = (state as OrderDetailSuccess).order;
    emit(OrderDetailActionLoading(currentOrder));

    final result = await _confirmReceiptUseCase(_orderId);

    result.fold(
      (failure) => emit(OrderDetailFailure(failure.message)),
      // Mock 环境下重新加载详情（数据不变，仅模拟流程）
      (_) => add(OrderDetailStarted(_orderId)),
    );
  }
}
