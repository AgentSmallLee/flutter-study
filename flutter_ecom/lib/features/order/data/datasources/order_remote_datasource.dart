import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/order_model.dart';

/// 订单远程数据源
class OrderRemoteDataSource {
  OrderRemoteDataSource(this._dioClient);

  final DioClient _dioClient;

  /// 获取订单列表
  Future<List<OrderModel>> getOrderList({
    int? status,
    required int page,
    required int pageSize,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'pageSize': pageSize,
    };
    if (status != null) {
      params['status'] = status;
    }

    final response = await _dioClient.get(
      ApiConstants.orderList,
      queryParameters: params,
    );

    final data = response.data as Map<String, dynamic>;
    // 兼容分页和直接列表两种格式
    final list = data['data'] is List
        ? (data['data'] as List)
        : (data['data']?['list'] as List? ?? []);

    return list
        .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 获取订单详情
  Future<OrderModel> getOrderDetail(String orderId) async {
    final response = await _dioClient.get(
      '${ApiConstants.orderDetail}$orderId',
    );
    final data = response.data as Map<String, dynamic>;
    final orderData = data['data'];
    if (orderData is List && orderData.isNotEmpty) {
      return OrderModel.fromJson(orderData.first as Map<String, dynamic>);
    }
    if (orderData is Map<String, dynamic>) {
      return OrderModel.fromJson(orderData);
    }
    throw Exception('订单不存在');
  }

  /// 取消订单
  Future<void> cancelOrder(String orderId) async {
    // Mock 模式下直接返回成功
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// 确认收货
  Future<void> confirmReceipt(String orderId) async {
    // Mock 模式下直接返回成功
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
