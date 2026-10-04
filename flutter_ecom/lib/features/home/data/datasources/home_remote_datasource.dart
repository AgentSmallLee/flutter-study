import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/base_response.dart';
import '../../../../core/network/dio_client.dart';
import '../models/banner_model.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';

/// 首页远程数据源
///
/// 面试讲解点：
/// DataSource 负责具体的数据获取，
/// Repository 通过 DataSource 获取数据，
/// 这样 Repository 不需要知道数据来自 API 还是本地缓存。
/// 将来如果加了缓存策略，只需在 Repository 中加逻辑，
/// 不需要改 DataSource。
class HomeRemoteDataSource {
  HomeRemoteDataSource(this._dioClient);

  final DioClient _dioClient;

  /// 获取 Banner 列表
  Future<List<BannerModel>> getBanners() async {
    final response = await _dioClient.get(ApiConstants.banners);
    final baseResponse = BaseResponse.fromJsonList(
      response.data as Map<String, dynamic>,
      (json) => BannerModel.fromJson(json as Map<String, dynamic>),
    );
    return baseResponse.data ?? [];
  }

  /// 获取分类列表
  Future<List<CategoryModel>> getCategories() async {
    final response = await _dioClient.get(ApiConstants.categories);
    final baseResponse = BaseResponse.fromJsonList(
      response.data as Map<String, dynamic>,
      (json) => CategoryModel.fromJson(json as Map<String, dynamic>),
    );
    return baseResponse.data ?? [];
  }

  /// 获取推荐商品列表
  Future<PaginationData<ProductModel>> getRecommendProducts({
    required int page,
    required int pageSize,
  }) async {
    final response = await _dioClient.get(
      ApiConstants.recommendProducts,
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
      },
    );
    final json = response.data as Map<String, dynamic>;
    final dataJson = json['data'] as Map<String, dynamic>? ?? {};

    return PaginationData.fromJson(
      dataJson,
      (json) => ProductModel.fromJson(json as Map<String, dynamic>),
    );
  }
}
