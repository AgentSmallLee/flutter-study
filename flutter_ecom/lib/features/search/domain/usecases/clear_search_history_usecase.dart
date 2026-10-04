import '../repositories/search_repository.dart';

/// 清空搜索历史 UseCase
class ClearSearchHistoryUseCase {
  ClearSearchHistoryUseCase(this._repository);
  final SearchRepository _repository;

  Future<void> call() => _repository.clearSearchHistory();
}
