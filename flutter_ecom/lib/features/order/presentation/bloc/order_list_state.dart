import 'package:equatable/equatable.dart';
import '../../domain/entities/order_entity.dart';

/// 订单列表状态
enum OrderListStatus {
  initial,  // 初始
  loading,  // 加载中
  success,  // 加载成功
  failure,  // 加载失败
}

/// 单个 Tab 的缓存数据
class OrderTabCache extends Equatable {
  const OrderTabCache({
    required this.orders,
    required this.currentPage,
    required this.hasMore,
  });

  final List<OrderEntity> orders;
  final int currentPage;
  final bool hasMore;

  @override
  List<Object?> get props => [orders, currentPage, hasMore];
}

/// 订单列表状态类
///
/// 面试讲解点：
/// 用单状态类 + 枚举的方式，因为多个状态共享相同字段（订单列表、分页信息等），
/// 避免多态子类重复定义字段。
///
/// 多 Tab 缓存策略：已加载过的 Tab 数据缓存在 `cachedOrders` 中，
/// 切换 Tab 时优先使用缓存，避免重复请求，提升体验。
class OrderListState extends Equatable {
  const OrderListState({
    this.status = OrderListStatus.initial,
    this.orders = const [],
    this.currentStatus,
    this.currentPage = 1,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.errorMessage,
    this.cachedOrders = const {},
  });

  final OrderListStatus status;
  final List<OrderEntity> orders;

  /// 当前筛选的状态，null 表示全部
  final int? currentStatus;

  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;
  final String? errorMessage;

  /// 各 Tab 缓存，key 为 status（null 表示全部）
  final Map<int?, OrderTabCache> cachedOrders;

  OrderListState copyWith({
    OrderListStatus? status,
    List<OrderEntity>? orders,
    int? currentStatus,
    bool clearStatus = false,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
    Map<int?, OrderTabCache>? cachedOrders,
  }) {
    return OrderListState(
      status: status ?? this.status,
      orders: orders ?? this.orders,
      currentStatus: clearStatus ? null : (currentStatus ?? this.currentStatus),
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      cachedOrders: cachedOrders ?? this.cachedOrders,
    );
  }

  @override
  List<Object?> get props => [
        status,
        orders,
        currentStatus,
        currentPage,
        hasMore,
        isLoadingMore,
        errorMessage,
        cachedOrders,
      ];
}
