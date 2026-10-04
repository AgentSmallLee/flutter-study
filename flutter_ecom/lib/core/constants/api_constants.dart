/// 全局 API 常量配置
class ApiConstants {
  ApiConstants._();

  /// 基础 URL（Mock 模式下不实际使用，但仍需要配置）
  static const String baseUrl = 'https://api.example.com';

  /// 连接超时时间（毫秒）
  static const int connectTimeout = 15000;

  /// 接收超时时间（毫秒）
  static const int receiveTimeout = 15000;

  /// 发送超时时间（毫秒）
  static const int sendTimeout = 15000;

  // ============ 接口路径 ============

  // 认证相关
  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';
  static const String userProfile = '/api/user/profile';

  // 首页相关
  static const String banners = '/api/home/banners';
  static const String categories = '/api/home/categories';
  static const String recommendProducts = '/api/products/recommend';

  // 商品相关
  static const String productList = '/api/products';
  static const String productDetail = '/api/products/'; // + id
  static const String searchProducts = '/api/products/search';

  // 订单相关
  static const String orderList = '/api/orders';
  static const String orderDetail = '/api/orders/'; // + id

  /// 分页默认页码
  static const int defaultPage = 1;

  /// 分页默认每页数量
  static const int defaultPageSize = 20;
}
