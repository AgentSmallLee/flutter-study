import 'package:equatable/equatable.dart';

/// 订单列表事件
abstract class OrderListEvent extends Equatable {
  const OrderListEvent();

  @override
  List<Object?> get props => [];
}

/// 加载订单列表
class OrderListLoaded extends OrderListEvent {
  const OrderListLoaded({this.status});

  /// 订单状态筛选，null 表示全部
  final int? status;

  @override
  List<Object?> get props => [status];
}

/// 下拉刷新
class OrderListRefreshed extends OrderListEvent {
  const OrderListRefreshed();
}

/// 加载更多
class OrderListLoadMore extends OrderListEvent {
  const OrderListLoadMore();
}
