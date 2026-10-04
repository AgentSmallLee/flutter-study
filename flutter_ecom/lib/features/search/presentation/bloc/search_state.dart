import 'package:equatable/equatable.dart';
import '../../../../features/home/domain/entities/product_entity.dart';

/// 搜索状态枚举
enum SearchStatus {
  initial,    // 初始状态（显示历史+热门）
  suggestion, // 建议状态（输入中）
  loading,    // 搜索加载中
  success,    // 搜索成功
  failure,    // 搜索失败
}

/// 搜索页状态
///
/// 面试讲解点：
/// 搜索页的状态比较多，用一个 enum 描述当前状态，
/// 而不是用抽象类 + 子类的方式，
/// 因为不同状态之间共享很多字段（keyword、history 等）。
class SearchState extends Equatable {
  const SearchState({
    this.status = SearchStatus.initial,
    this.keyword = '',
    this.products = const [],
    this.history = const [],
    this.hotKeywords = const [],
    this.currentPage = 1,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  final SearchStatus status;
  final String keyword;
  final List<ProductEntity> products;
  final List<String> history;
  final List<String> hotKeywords;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;
  final String? errorMessage;

  SearchState copyWith({
    SearchStatus? status,
    String? keyword,
    List<ProductEntity>? products,
    List<String>? history,
    List<String>? hotKeywords,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SearchState(
      status: status ?? this.status,
      keyword: keyword ?? this.keyword,
      products: products ?? this.products,
      history: history ?? this.history,
      hotKeywords: hotKeywords ?? this.hotKeywords,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        keyword,
        products,
        history,
        hotKeywords,
        currentPage,
        hasMore,
        isLoadingMore,
        errorMessage,
      ];
}
