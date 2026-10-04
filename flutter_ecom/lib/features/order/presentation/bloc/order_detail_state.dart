import 'package:equatable/equatable.dart';
import '../../domain/entities/order_entity.dart';

/// 订单详情状态
abstract class OrderDetailState extends Equatable {
  const OrderDetailState();

  @override
  List<Object> get props => [];
}

class OrderDetailInitial extends OrderDetailState {
  const OrderDetailInitial();
}

class OrderDetailLoading extends OrderDetailState {
  const OrderDetailLoading();
}

class OrderDetailSuccess extends OrderDetailState {
  const OrderDetailSuccess(this.order);

  final OrderEntity order;

  @override
  List<Object> get props => [order];
}

class OrderDetailFailure extends OrderDetailState {
  const OrderDetailFailure(this.message);

  final String message;

  @override
  List<Object> get props => [message];
}

/// 操作中状态（取消订单、确认收货等操作的 loading）
class OrderDetailActionLoading extends OrderDetailState {
  const OrderDetailActionLoading(this.order);

  final OrderEntity order;

  @override
  List<Object> get props => [order];
}
