import 'package:bloc/bloc.dart';

import '../../../../core/constants/api_constants.dart';
import '../../domain/entities/banner_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/usecases/get_banners_usecase.dart';
import '../../domain/usecases/get_categories_usecase.dart';
import '../../domain/usecases/get_recommend_products_usecase.dart';
import 'home_event.dart';
import 'home_state.dart';

/// 首页 Bloc
///
/// 面试讲解点：
/// Bloc 的核心思想：事件驱动的单向数据流。
///
/// 数据流：
/// UI → Event → Bloc → State → UI
///
/// 好处：
/// 1. 状态集中管理，UI 只是状态的映射（状态 = 视图）
/// 2. 状态变化可预测、可追踪（配合 BlocObserver 可以看到所有状态变化）
/// 3. 便于测试（给定初始状态 + 事件，断言最终状态）
///
/// 这里首页的数据加载策略：
/// - 首次加载：Banner + 分类 + 第一页商品 同时加载
/// - 下拉刷新：重置所有数据，重新加载
/// - 上拉加载：只加载下一页商品，追加到列表
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({
    required GetBannersUseCase getBannersUseCase,
    required GetCategoriesUseCase getCategoriesUseCase,
    required GetRecommendProductsUseCase getRecommendProductsUseCase,
  })  : _getBannersUseCase = getBannersUseCase,
        _getCategoriesUseCase = getCategoriesUseCase,
        _getRecommendProductsUseCase = getRecommendProductsUseCase,
        super(const HomeInitial()) {
    // 注册事件处理器
    on<HomeInitialEvent>(_onInitial);
    on<HomeRefreshEvent>(_onRefresh);
    on<HomeLoadMoreEvent>(_onLoadMore);
  }

  final GetBannersUseCase _getBannersUseCase;
  final GetCategoriesUseCase _getCategoriesUseCase;
  final GetRecommendProductsUseCase _getRecommendProductsUseCase;

  /// 首次加载
  Future<void> _onInitial(
    HomeInitialEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(const HomeLoading());
    await _loadData(emit, page: 1, isRefresh: true);
  }

  /// 下拉刷新
  Future<void> _onRefresh(
    HomeRefreshEvent event,
    Emitter<HomeState> emit,
  ) async {
    // 如果已经有数据，保持数据显示（不切到 loading）
    if (state is HomeSuccess) {
      await _loadData(emit, page: 1, isRefresh: true);
    } else {
      emit(const HomeLoading());
      await _loadData(emit, page: 1, isRefresh: true);
    }
  }

  /// 加载更多
  Future<void> _onLoadMore(
    HomeLoadMoreEvent event,
    Emitter<HomeState> emit,
  ) async {
    final current = state;
    if (current is! HomeSuccess) return;
    if (current.isLoadingMore || !current.hasMore) return;

    emit(current.copyWith(isLoadingMore: true));

    final result = await _getRecommendProductsUseCase(
      page: current.currentPage + 1,
      pageSize: ApiConstants.defaultPageSize,
    );

    result.fold(
      (failure) {
        // 加载更多失败不展示大的错误状态，只取消 loading 标志
        emit(current.copyWith(isLoadingMore: false));
      },
      (newProducts) {
        final allProducts = [...current.products, ...newProducts];
        emit(current.copyWith(
          products: allProducts,
          currentPage: current.currentPage + 1,
          hasMore: newProducts.length >= ApiConstants.defaultPageSize,
          isLoadingMore: false,
        ));
      },
    );
  }

  /// 加载首页数据（Banner + 分类 + 商品）
  ///
  /// 使用 Future.wait 并发请求三个接口，提高加载速度。
  /// 策略：商品加载成功即展示页面，Banner 和分类失败不影响整体（显示空）。
  Future<void> _loadData(
    Emitter<HomeState> emit, {
    required int page,
    required bool isRefresh,
  }) async {
    // 分别发起三个请求（并发执行）
    final bannersFuture = _getBannersUseCase();
    final categoriesFuture = _getCategoriesUseCase();
    final productsFuture = _getRecommendProductsUseCase(
      page: page,
      pageSize: ApiConstants.defaultPageSize,
    );

    // 等待所有请求完成
    final bannersResult = await bannersFuture;
    final categoriesResult = await categoriesFuture;
    final productsResult = await productsFuture;

    // 提取 Banner 和分类数据（失败则给空列表）
    final List<BannerEntity> banners = bannersResult.fold(
      (_) => [],
      (list) => list,
    );
    final List<CategoryEntity> categories = categoriesResult.fold(
      (_) => [],
      (list) => list,
    );

    // 商品失败则整体失败，成功则展示所有数据
    productsResult.fold(
      (failure) => emit(HomeFailure(failure)),
      (products) => emit(HomeSuccess(
            banners: banners,
            categories: categories,
            products: products,
            currentPage: page,
            hasMore: products.length >= ApiConstants.defaultPageSize,
          )),
    );
  }
}
