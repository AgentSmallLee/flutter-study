import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/api_constants.dart';
import '../../domain/usecases/get_order_list_usecase.dart';
import 'order_list_event.dart';
import 'order_list_state.dart';

/// 订单列表 Bloc
///
/// 面试讲解点：
/// 订单列表支持状态筛选（全部/待付款/待发货/待收货/已完成），
/// 使用「多 Tab 缓存策略」：已加载过的 Tab 数据缓存在 cachedOrders 中，
/// 切换 Tab 时优先使用缓存，避免重复请求；下拉刷新才强制刷新。
///
/// 使用单状态类 + 枚举的设计，和搜索页模式一致。
class OrderListBloc extends Bloc<OrderListEvent, OrderListState> {
  OrderListBloc(this._getOrderListUseCase) : super(const OrderListState()) {
    on<OrderListLoaded>(_onLoaded);
    on<OrderListRefreshed>(_onRefreshed);
    on<OrderListLoadMore>(_onLoadMore);
  }

  final GetOrderListUseCase _getOrderListUseCase;

  /// 加载订单列表（首次或切换状态）
  ///
  /// 逻辑：
  /// 1. 如果目标 Tab 已有缓存且状态没变，直接使用缓存，不发请求
  /// 2. 否则走 loading + 网络请求
  Future<void> _onLoaded(
    OrderListLoaded event,
    Emitter<OrderListState> emit,
  ) async {
    final cache = state.cachedOrders[event.status];

    // 如果已有缓存，直接切换到缓存数据
    if (cache != null) {
      emit(state.copyWith(
        status: OrderListStatus.success,
        orders: cache.orders,
        currentStatus: event.status,
        clearStatus: event.status == null,
        currentPage: cache.currentPage,
        hasMore: cache.hasMore,
        clearError: true,
      ));
      return;
    }

    // 没有缓存，走加载流程
    emit(state.copyWith(
      status: OrderListStatus.loading,
      currentStatus: event.status,
      clearStatus: event.status == null,
      currentPage: 1,
      hasMore: true,
      clearError: true,
    ));

    final result = await _getOrderListUseCase(
      status: event.status,
      page: 1,
      pageSize: ApiConstants.defaultPageSize,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: OrderListStatus.failure,
        errorMessage: failure.message,
      )),
      (orders) {
        // 存入缓存
        final newCached = Map<int?, OrderTabCache>.from(state.cachedOrders);
        newCached[event.status] = OrderTabCache(
          orders: orders,
          currentPage: 1,
          hasMore: orders.length >= ApiConstants.defaultPageSize,
        );

        emit(state.copyWith(
          status: OrderListStatus.success,
          orders: orders,
          currentPage: 1,
          hasMore: orders.length >= ApiConstants.defaultPageSize,
          cachedOrders: newCached,
        ));
      },
    );
  }

  /// 下拉刷新
  ///
  /// 强制从第一页重新加载，并更新缓存
  Future<void> _onRefreshed(
    OrderListRefreshed event,
    Emitter<OrderListState> emit,
  ) async {
    final result = await _getOrderListUseCase(
      status: state.currentStatus,
      page: 1,
      pageSize: ApiConstants.defaultPageSize,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: OrderListStatus.failure,
        errorMessage: failure.message,
      )),
      (orders) {
        // 更新缓存
        final newCached = Map<int?, OrderTabCache>.from(state.cachedOrders);
        newCached[state.currentStatus] = OrderTabCache(
          orders: orders,
          currentPage: 1,
          hasMore: orders.length >= ApiConstants.defaultPageSize,
        );

        emit(state.copyWith(
          status: OrderListStatus.success,
          orders: orders,
          currentPage: 1,
          hasMore: orders.length >= ApiConstants.defaultPageSize,
          cachedOrders: newCached,
        ));
      },
    );
  }

  /// 加载更多
  Future<void> _onLoadMore(
    OrderListLoadMore event,
    Emitter<OrderListState> emit,
  ) async {
    if (state.status != OrderListStatus.success) return;
    if (state.isLoadingMore || !state.hasMore) return;

    emit(state.copyWith(isLoadingMore: true));

    final result = await _getOrderListUseCase(
      status: state.currentStatus,
      page: state.currentPage + 1,
      pageSize: ApiConstants.defaultPageSize,
    );

    result.fold(
      (failure) => emit(state.copyWith(isLoadingMore: false)),
      (newOrders) {
        final allOrders = [...state.orders, ...newOrders];
        final nextPage = state.currentPage + 1;
        final hasMore = newOrders.length >= ApiConstants.defaultPageSize;

        // 更新缓存
        final newCached = Map<int?, OrderTabCache>.from(state.cachedOrders);
        newCached[state.currentStatus] = OrderTabCache(
          orders: allOrders,
          currentPage: nextPage,
          hasMore: hasMore,
        );

        emit(state.copyWith(
          orders: allOrders,
          currentPage: nextPage,
          hasMore: hasMore,
          isLoadingMore: false,
          cachedOrders: newCached,
        ));
      },
    );
  }
}
