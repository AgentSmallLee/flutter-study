import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/base_response.dart';
import '../../../../core/network/dio_client.dart';
import '../models/product_detail_model.dart';

/// 商品远程数据源
class ProductRemoteDataSource {
  ProductRemoteDataSource(this._dioClient);

  final DioClient _dioClient;

  /// 获取商品详情
  Future<ProductDetailModel> getProductDetail(int productId) async {
    final response = await _dioClient.get(
      '${ApiConstants.productDetail}$productId',
    );
    final baseResponse = BaseResponse<ProductDetailModel>.fromJson(
      response.data as Map<String, dynamic>,
      (json) =>
          ProductDetailModel.fromJson(json as Map<String, dynamic>),
    );
    return baseResponse.data!;
  }
}
