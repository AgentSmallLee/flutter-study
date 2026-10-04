import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../../../home/data/models/product_model.dart';
import '../../../home/domain/entities/product_entity.dart';
import '../../domain/repositories/search_repository.dart';

/// 搜索 Repository 实现
///
/// 面试讲解点：
/// SearchRepository 同时管理远程数据（搜索结果）和本地数据（搜索历史），
/// 是一个典型的「混合数据源」Repository。
/// 上层只需要调用接口，不需要知道数据来自网络还是本地。
class SearchRepositoryImpl implements SearchRepository {
  SearchRepositoryImpl(this._dioClient, this._sharedPreferences);

  final DioClient _dioClient;
  final SharedPreferences _sharedPreferences;

  /// 热门搜索关键词（模拟接口，实际项目中从后端获取）
  static const List<String> _hotKeywords = [
    '手机',
    '笔记本电脑',
    '耳机',
    '运动鞋',
    '连衣裙',
    '口红',
    '零食',
    '玩具',
  ];

  @override
  Future<Result<List<ProductEntity>>> searchProducts({
    required String keyword,
    required int page,
    required int pageSize,
  }) async {
    try {
      final response = await _dioClient.get(
        ApiConstants.searchProducts,
        queryParameters: {
          'keyword': keyword,
          'page': page,
          'pageSize': pageSize,
        },
      );
      final data = response.data as Map<String, dynamic>;
      final dataList = data['data'] is List
          ? (data['data'] as List)
          : (data['data']?['list'] as List? ?? []);
      final products = dataList
          .map((e) =>
              ProductModel.fromJson(e as Map<String, dynamic>).toEntity())
          .toList();
      return Right(products);
    } catch (e) {
      return Left(ErrorHandler.handleError(e));
    }
  }

  @override
  Future<List<String>> getSearchHistory() async {
    final history =
        _sharedPreferences.getStringList(StorageKeys.searchHistory) ?? [];
    return history;
  }

  @override
  Future<void> saveSearchHistory(String keyword) async {
    if (keyword.trim().isEmpty) return;
    final history =
        _sharedPreferences.getStringList(StorageKeys.searchHistory) ?? [];
    // 去重：如果已存在则先移除再插入到最前面
    history.remove(keyword);
    history.insert(0, keyword);
    // 最多保留 10 条
    if (history.length > 10) {
      history.removeRange(10, history.length);
    }
    await _sharedPreferences.setStringList(StorageKeys.searchHistory, history);
  }

  @override
  Future<void> clearSearchHistory() async {
    await _sharedPreferences.remove(StorageKeys.searchHistory);
  }

  @override
  Future<List<String>> getHotKeywords() async {
    return _hotKeywords;
  }
}
