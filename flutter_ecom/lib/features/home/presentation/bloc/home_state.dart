import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/banner_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/product_entity.dart';

/// 首页状态
///
/// 面试讲解点：
/// 状态建模原则：
/// 1. 状态要完整描述 UI 的所有可能情况
/// 2. 非法状态不可能存在（比如不能同时是 loading 又有数据）
/// 3. 使用值类型（不可变），状态更新总是创建新对象
///
/// 这里用抽象类 + 子类的方式，类似 Kotlin 的 sealed class。
/// 每种状态携带它需要的数据：
/// - Loading：不需要数据
/// - Success：携带 Banner、分类、商品列表
/// - Failure：携带错误信息
abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object> get props => [];
}

/// 初始状态
class HomeInitial extends HomeState {
  const HomeInitial();
}

/// 加载中状态（首次加载）
class HomeLoading extends HomeState {
  const HomeLoading();
}

/// 加载成功状态
class HomeSuccess extends HomeState {
  const HomeSuccess({
    required this.banners,
    required this.categories,
    required this.products,
    required this.currentPage,
    required this.hasMore,
    this.isLoadingMore = false,
  });

  final List<BannerEntity> banners;
  final List<CategoryEntity> categories;
  final List<ProductEntity> products;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingMore;

  /// 复制并更新部分字段
  HomeSuccess copyWith({
    List<BannerEntity>? banners,
    List<CategoryEntity>? categories,
    List<ProductEntity>? products,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return HomeSuccess(
      banners: banners ?? this.banners,
      categories: categories ?? this.categories,
      products: products ?? this.products,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object> get props => [
        banners,
        categories,
        products,
        currentPage,
        hasMore,
        isLoadingMore,
      ];
}

/// 加载失败状态
class HomeFailure extends HomeState {
  const HomeFailure(this.failure);

  final Failure failure;

  String get message => failure.message;

  @override
  List<Object> get props => [failure];
}
