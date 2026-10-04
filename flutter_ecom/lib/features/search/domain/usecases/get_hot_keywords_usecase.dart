import '../repositories/search_repository.dart';

/// 获取热门搜索 UseCase
class GetHotKeywordsUseCase {
  GetHotKeywordsUseCase(this._repository);
  final SearchRepository _repository;

  Future<List<String>> call() => _repository.getHotKeywords();
}
