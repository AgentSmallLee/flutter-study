import '../repositories/search_repository.dart';

/// 保存搜索历史 UseCase
class SaveSearchHistoryUseCase {
  SaveSearchHistoryUseCase(this._repository);
  final SearchRepository _repository;

  Future<void> call(String keyword) =>
      _repository.saveSearchHistory(keyword);
}
