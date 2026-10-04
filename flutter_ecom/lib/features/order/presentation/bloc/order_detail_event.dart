import 'package:equatable/equatable.dart';

/// 订单详情事件
abstract class OrderDetailEvent extends Equatable {
  const OrderDetailEvent();

  @override
  List<Object> get props => [];
}

/// 进入页面，加载订单详情
class OrderDetailStarted extends OrderDetailEvent {
  const OrderDetailStarted(this.orderId);

  final String orderId;

  @override
  List<Object> get props => [orderId];
}

/// 取消订单
class OrderDetailCancelled extends OrderDetailEvent {
  const OrderDetailCancelled();
}

/// 确认收货
class OrderDetailConfirmed extends OrderDetailEvent {
  const OrderDetailConfirmed();
}
