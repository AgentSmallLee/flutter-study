import 'package:equatable/equatable.dart';

/// 搜索页事件
abstract class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object> get props => [];
}

/// 初始化（加载历史和热门）
class SearchInitialized extends SearchEvent {
  const SearchInitialized();
}

/// 搜索关键词变化
class SearchKeywordChanged extends SearchEvent {
  const SearchKeywordChanged(this.keyword);

  final String keyword;

  @override
  List<Object> get props => [keyword];
}

/// 提交搜索
class SearchSubmitted extends SearchEvent {
  const SearchSubmitted(this.keyword);

  final String keyword;

  @override
  List<Object> get props => [keyword];
}

/// 加载更多
class SearchLoadMore extends SearchEvent {
  const SearchLoadMore();
}

/// 清空搜索历史
class SearchHistoryCleared extends SearchEvent {
  const SearchHistoryCleared();
}

/// 删除单个搜索历史
class SearchHistoryItemRemoved extends SearchEvent {
  const SearchHistoryItemRemoved(this.keyword);

  final String keyword;

  @override
  List<Object> get props => [keyword];
}
