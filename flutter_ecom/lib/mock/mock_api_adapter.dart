import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../core/utils/logger.dart';

/// Mock API 适配器
///
/// 自定义 Dio 的 HttpClientAdapter，根据请求路径返回本地 Mock JSON 数据。
/// 这样上层代码完全不需要改动，只需替换 Dio 的 adapter 即可切换 Mock/真实环境。
///
/// 面试讲解点：
/// 这种 Mock 方案的好处：
/// 1. 对上层业务代码完全透明，Repository 层感知不到 Mock 的存在
/// 2. 可以随时切换到真实后端，只需改一行配置
/// 3. 支持模拟网络延迟、错误等场景，便于调试各种状态
class MockApiAdapter implements HttpClientAdapter {
  MockApiAdapter._();

  static final MockApiAdapter instance = MockApiAdapter._();

  /// 模拟网络延迟范围（毫秒）
  static const int _minDelay = 300;
  static const int _maxDelay = 800;

  /// URL 路径到 Mock 资源文件的映射
  static final Map<String, String> _pathMap = {
    '/api/auth/login': 'mock/assets/user.json',
    '/api/auth/register': 'mock/assets/user.json',
    '/api/user/profile': 'mock/assets/user.json',
    '/api/home/banners': 'mock/assets/banners.json',
    '/api/home/categories': 'mock/assets/categories.json',
    '/api/products/recommend': 'mock/assets/products.json',
    '/api/products': 'mock/assets/products.json',
    '/api/products/search': 'mock/assets/products.json',
    '/api/orders': 'mock/assets/orders.json',
  };

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;
    AppLogger.i('Mock API request: ${options.method} $path');

    // 模拟网络延迟
    await Future.delayed(
      Duration(
        milliseconds: _minDelay +
            DateTime.now().millisecondsSinceEpoch % (_maxDelay - _minDelay),
      ),
    );

    // 查找对应的 mock 文件
    String? mockFile;
    for (final entry in _pathMap.entries) {
      if (path.startsWith(entry.key) || path == entry.key) {
        mockFile = entry.value;
        break;
      }
    }

    // 商品详情特殊处理：/api/products/:id
    if (mockFile == null && path.startsWith('/api/products/')) {
      mockFile = 'mock/assets/product_detail.json';
    }

    // 订单详情特殊处理：/api/orders/:id
    if (mockFile == null && path.startsWith('/api/orders/')) {
      mockFile = 'mock/assets/orders.json';
    }

    if (mockFile == null) {
      AppLogger.w('No mock file found for path: $path');
      return _buildErrorResponse(404, 'Not found: $path');
    }

    try {
      // 从 assets 读取 JSON 文件
      final jsonString = await rootBundle.loadString(mockFile);
      final data = json.decode(jsonString);

      // 处理分页参数
      final page = options.queryParameters['page'] as int? ?? 1;
      final pageSize = options.queryParameters['pageSize'] as int? ?? 20;

      dynamic responseData = data;

      // 订单详情：从列表中筛选单条
      if (path.startsWith('/api/orders/') && path != '/api/orders') {
        final orderId = path.replaceFirst('/api/orders/', '');
        if (data is Map && data['data'] is List) {
          final list = data['data'] as List;
          final order = list.firstWhere(
            (e) => e['id'] == orderId || e['orderNo'] == orderId,
            orElse: () => null,
          );
          responseData = {
            'code': 200,
            'message': 'success',
            'data': order,
          };
        }
      }
      // 订单列表：按 status 过滤 + 分页
      else if (path == '/api/orders' && data is Map && data['data'] is List) {
        final list = data['data'] as List;
        final status = options.queryParameters['status'];
        final filtered = status != null
            ? list.where((e) => e['status'] == status).toList()
            : list;
        final start = (page - 1) * pageSize;
        final end = start + pageSize;
        final paginatedList =
            filtered.sublist(start, end > filtered.length ? filtered.length : end);
        responseData = {
          'code': 200,
          'message': 'success',
          'data': paginatedList,
        };
      }
      // 如果 data 里是 list 且有分页参数，做分页处理
      else if (data is Map && data['data'] is List && path.contains('product')) {
        final list = data['data'] as List;
        final start = (page - 1) * pageSize;
        final end = start + pageSize;
        final paginatedList =
            list.sublist(start, end > list.length ? list.length : end);

        responseData = {
          'code': 200,
          'message': 'success',
          'data': {
            'list': paginatedList,
            'total': list.length,
            'page': page,
            'pageSize': pageSize,
            'hasMore': end < list.length,
          },
        };
      }

      AppLogger.d('Mock response from: $mockFile');

      return ResponseBody.fromString(
        json.encode(responseData),
        200,
        headers: {
          HttpHeaders.contentTypeHeader: [
            ContentType.json.value,
          ],
        },
      );
    } catch (e) {
      AppLogger.e('Failed to load mock file: $mockFile, error: $e');
      return _buildErrorResponse(500, 'Mock data error: $e');
    }
  }

  /// 构造错误响应
  ResponseBody _buildErrorResponse(int statusCode, String message) {
    final body = json.encode({
      'code': statusCode,
      'message': message,
      'data': null,
    });
    return ResponseBody.fromString(
      body,
      statusCode,
      headers: {
        HttpHeaders.contentTypeHeader: [ContentType.json.value],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
