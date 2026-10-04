import '../../../../core/error/failures.dart';
import '../entities/order_entity.dart';

/// 订单 Repository 接口
abstract class OrderRepository {
  /// 获取订单列表
  /// [status] 订单状态筛选，null 表示全部
  Future<Result<List<OrderEntity>>> getOrderList({
    int? status,
    required int page,
    required int pageSize,
  });

  /// 获取订单详情
  Future<Result<OrderEntity>> getOrderDetail(String orderId);

  /// 取消订单
  Future<Result<void>> cancelOrder(String orderId);

  /// 确认收货
  Future<Result<void>> confirmReceipt(String orderId);
}
