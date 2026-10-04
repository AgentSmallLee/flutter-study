import '../repositories/search_repository.dart';

/// 获取搜索历史 UseCase
class GetSearchHistoryUseCase {
  GetSearchHistoryUseCase(this._repository);
  final SearchRepository _repository;

  Future<List<String>> call() => _repository.getSearchHistory();
}
