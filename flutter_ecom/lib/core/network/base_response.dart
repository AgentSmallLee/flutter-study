/// 通用网络响应包装类
///
/// 统一处理后端返回的 `{ code, message, data }` 结构。
///
/// 面试讲解点：
/// 包装类的作用是统一处理业务状态码，将 HTTP 层和业务层分离。
/// HTTP 200 只代表网络请求成功，业务是否成功要看 code 字段。
class BaseResponse<T> {
  const BaseResponse({
    required this.code,
    required this.message,
    this.data,
  });

  final int code;
  final String message;
  final T? data;

  /// 业务是否成功
  bool get isSuccess => code == 200;

  /// 从 JSON 解析，需要传入 data 的解析函数
  factory BaseResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? dataParser,
  ) {
    return BaseResponse<T>(
      code: json['code'] as int? ?? -1,
      message: json['message']?.toString() ?? '',
      data: json['data'] != null && dataParser != null
          ? dataParser(json['data'])
          : json['data'] as T?,
    );
  }

  /// 列表类型 data 的便捷构造
  static BaseResponse<List<T>> fromJsonList<T>(
    Map<String, dynamic> json,
    T Function(dynamic) itemParser,
  ) {
    final dataList = json['data'] is List ? json['data'] as List : [];
    return BaseResponse<List<T>>(
      code: json['code'] as int? ?? -1,
      message: json['message']?.toString() ?? '',
      data: dataList.map((e) => itemParser(e)).toList(),
    );
  }
}

/// 分页数据包装
class PaginationData<T> {
  const PaginationData({
    required this.list,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });

  final List<T> list;
  final int total;
  final int page;
  final int pageSize;
  final bool hasMore;

  factory PaginationData.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) itemParser,
  ) {
    final list = (json['list'] as List<dynamic>?) ?? [];
    return PaginationData<T>(
      list: list.map((e) => itemParser(e)).toList(),
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 20,
      hasMore: json['hasMore'] as bool? ?? false,
    );
  }
}
