import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/base_response.dart';
import '../../../../core/network/dio_client.dart';
import '../models/user_model.dart';

/// 认证远程数据源
class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dioClient);

  final DioClient _dioClient;

  /// 登录
  Future<UserModel> login({
    required String phone,
    required String password,
  }) async {
    final response = await _dioClient.post(
      ApiConstants.login,
      data: {
        'phone': phone,
        'password': password,
      },
    );
    final baseResponse = BaseResponse<UserModel>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => UserModel.fromJson(json as Map<String, dynamic>),
    );
    return baseResponse.data!;
  }

  /// 获取用户信息
  Future<UserModel> getUserProfile() async {
    final response = await _dioClient.get(ApiConstants.userProfile);
    final baseResponse = BaseResponse<UserModel>.fromJson(
      response.data as Map<String, dynamic>,
      (json) => UserModel.fromJson(json as Map<String, dynamic>),
    );
    return baseResponse.data!;
  }
}
