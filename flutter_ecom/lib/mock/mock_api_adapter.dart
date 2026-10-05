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
    //
    // 面试讲解点：
    // 路径匹配的优先级问题——
    // 必须先判断精确匹配，再判断前缀匹配，否则像 /api/products/1 这样的详情路径
    // 会被 /api/products 这个前缀提前拦截，导致返回列表数据而不是详情数据。
    String? mockFile;

    // 1. 先判断商品详情：/api/products/:id（路径里包含数字 id）
    // 注意：必须放在 /api/products 前缀匹配之前，否则会被列表接口拦截
    if (path.startsWith('/api/products/') && path != '/api/products/search') {
      final idPart = path.replaceFirst('/api/products/', '');
      // 检查 idPart 是不是数字（商品详情路径）
      if (int.tryParse(idPart) != null) {
        mockFile = 'mock/assets/product_detail.json';
      }
    }

    // 2. 再遍历通用路径映射
    if (mockFile == null) {
      for (final entry in _pathMap.entries) {
        if (path.startsWith(entry.key) || path == entry.key) {
          mockFile = entry.value;
          break;
        }
      }
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

      // 商品详情：从商品列表中找对应 id 的商品，合并详情模板数据
      // 面试讲解点：
      // Mock 数据中商品列表和商品详情是分开的两份文件。
      // 商品详情接口需要返回"列表基础信息 + 详情扩展信息"的完整数据。
      // 实现思路：从 products.json 找到对应 id 的商品（名称、价格、主图等基础字段），
      // 再用 product_detail.json 里的详情字段（specs、detailImages、service 等）补全，
      // 这样不同 id 的商品信息都不一样，和列表页显示一致，更接近真实后端。
      if (mockFile == 'mock/assets/product_detail.json' &&
          data is Map &&
          data['data'] is Map) {
        final productId = int.tryParse(path.replaceFirst('/api/products/', '')) ?? 1;

        // 1. 从商品列表文件中读取对应 id 的商品基础信息
        final listJsonString =
            await rootBundle.loadString('mock/assets/products.json');
        final listData = json.decode(listJsonString);
        Map<String, dynamic>? baseProduct;
        if (listData is Map && listData['data'] is List) {
          final list = listData['data'] as List;
          try {
            baseProduct = list.firstWhere(
              (e) => e['id'] == productId,
              orElse: () => null,
            ) as Map<String, dynamic>?;
          } catch (_) {
            baseProduct = null;
          }
        }

        // 2. 详情模板数据（specs、detailImages、service 等扩展字段）
        final detailTemplate = data['data'] as Map<String, dynamic>;

        // 3. 合并：基础信息用列表中的，详情字段用模板的
        // 注意：列表里的 specs 是字符串数组，详情里是对象数组（带分组），格式不兼容
        // 所以 specs 强制用详情模板里的
        final skipKeys = {'specs'};
        final productData = <String, dynamic>{};
        if (baseProduct != null) {
          baseProduct.forEach((key, value) {
            if (!skipKeys.contains(key)) {
              productData[key] = value;
            }
          });
        } else {
          // 列表里找不到就用模板里的基础信息，id 替换掉
          productData.addAll(detailTemplate);
          productData['id'] = productId;
        }
        // 详情独有字段（列表里没有的，用模板补全）
        detailTemplate.forEach((key, value) {
          if (!productData.containsKey(key)) {
            productData[key] = value;
          }
        });

        // 4. 补全图片画廊（列表里 images 可能只有 3 张，详情页用 5 张）
        final seed = 'product$productId';
        if (productData['images'] == null ||
            (productData['images'] as List).length < 5) {
          productData['images'] = [
            'https://picsum.photos/seed/${seed}a/800/800',
            'https://picsum.photos/seed/${seed}b/800/800',
            'https://picsum.photos/seed/${seed}c/800/800',
            'https://picsum.photos/seed/${seed}d/800/800',
            'https://picsum.photos/seed/${seed}e/800/800',
          ];
        }
        // 详情图文
        productData['detailImages'] = [
          'https://picsum.photos/seed/detail${seed}1/750/600',
          'https://picsum.photos/seed/detail${seed}2/750/600',
          'https://picsum.photos/seed/detail${seed}3/750/600',
        ];

        responseData = {
          'code': 200,
          'message': 'success',
          'data': productData,
        };
      }
      // 订单详情：从列表中筛选单条
      if (path.startsWith('/api/orders/') && path != '/api/orders') {
        final orderId = path.replaceFirst('/api/orders/', '');
        AppLogger.d('Order detail request: orderId=$orderId, listLength=${(data['data'] as List?)?.length}');
        if (data is Map && data['data'] is List) {
          final list = data['data'] as List;
          final order = list.firstWhere(
            (e) => e['id'] == orderId || e['orderNo'] == orderId,
            orElse: () => null,
          );
          AppLogger.d('Order detail found: ${order != null ? order['orderNo'] : "NULL"}');
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
