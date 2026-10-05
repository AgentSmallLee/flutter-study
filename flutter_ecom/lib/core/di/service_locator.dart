import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/dio_client.dart';
import '../network/interceptors/auth_interceptor.dart';
import '../network/interceptors/error_interceptor.dart';
import '../network/interceptors/logging_interceptor.dart';
import '../../mock/mock_api_adapter.dart';

// ===== Home Module =====
import '../../features/home/data/datasources/home_remote_datasource.dart';
import '../../features/home/data/repositories/home_repository_impl.dart';
import '../../features/home/domain/repositories/home_repository.dart';
import '../../features/home/domain/usecases/get_banners_usecase.dart';
import '../../features/home/domain/usecases/get_categories_usecase.dart';
import '../../features/home/domain/usecases/get_recommend_products_usecase.dart';
import '../../features/home/presentation/bloc/home_bloc.dart';
import '../../features/home/presentation/bloc/home_event.dart';

// ===== Cart Module =====
import '../../features/cart/data/datasources/cart_local_datasource.dart';
import '../../features/cart/data/models/cart_item_hive_model.dart';
import '../../features/cart/data/repositories/cart_repository_impl.dart';
import '../../features/cart/domain/repositories/cart_repository.dart';
import '../../features/cart/domain/usecases/add_to_cart_usecase.dart';
import '../../features/cart/domain/usecases/clear_cart_usecase.dart';
import '../../features/cart/domain/usecases/get_cart_count_usecase.dart';
import '../../features/cart/domain/usecases/get_cart_usecase.dart';
import '../../features/cart/domain/usecases/remove_cart_item_usecase.dart';
import '../../features/cart/domain/usecases/toggle_select_usecase.dart';
import '../../features/cart/domain/usecases/update_quantity_usecase.dart';
import '../../features/cart/presentation/bloc/cart_bloc.dart';
import '../../features/cart/presentation/bloc/cart_event.dart';

// ===== Category Module =====
import '../../features/category/presentation/bloc/category_bloc.dart';
import '../../features/category/presentation/bloc/category_event.dart';

// ===== Product Detail Module =====
import '../../features/product_detail/data/datasources/product_remote_datasource.dart';
import '../../features/product_detail/data/models/product_detail_model.dart';
import '../../features/product_detail/data/repositories/product_repository_impl.dart';
import '../../features/product_detail/domain/repositories/product_repository.dart';
import '../../features/product_detail/domain/usecases/get_product_detail_usecase.dart';
import '../../features/product_detail/presentation/bloc/product_detail_bloc.dart';
import '../../features/product_detail/presentation/bloc/product_detail_event.dart';

// ===== Auth Module =====
import '../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/get_current_user_usecase.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/login_bloc.dart';

// ===== Order Module =====
import '../../features/order/data/datasources/order_remote_datasource.dart';
import '../../features/order/data/repositories/order_repository_impl.dart';
import '../../features/order/domain/repositories/order_repository.dart';
import '../../features/order/domain/usecases/cancel_order_usecase.dart';
import '../../features/order/domain/usecases/confirm_receipt_usecase.dart';
import '../../features/order/domain/usecases/get_order_detail_usecase.dart';
import '../../features/order/domain/usecases/get_order_list_usecase.dart';
import '../../features/order/presentation/bloc/order_detail_bloc.dart';
import '../../features/order/presentation/bloc/order_list_bloc.dart';

// ===== Search Module =====
import '../../features/search/data/repositories/search_repository_impl.dart';
import '../../features/search/domain/repositories/search_repository.dart';
import '../../features/search/domain/usecases/clear_search_history_usecase.dart';
import '../../features/search/domain/usecases/get_hot_keywords_usecase.dart';
import '../../features/search/domain/usecases/get_search_history_usecase.dart';
import '../../features/search/domain/usecases/save_search_history_usecase.dart';
import '../../features/search/domain/usecases/search_products_usecase.dart';
import '../../features/search/presentation/bloc/search_bloc.dart';

/// 全局服务定位器
///
/// 使用 get_it 实现依赖注入，所有单例/工厂都在这里注册。
///
/// 面试讲解点：
/// 为什么用依赖注入？
/// 1. 解耦：上层不依赖具体实现，只依赖抽象
/// 2. 便于测试：测试时可以替换为 Mock 实现
/// 3. 生命周期管理：统一管理单例的创建和销毁
final getIt = GetIt.instance;

/// 是否使用 Mock 数据
/// 面试时可以讲：通过配置切换 Mock/真实环境，无需修改业务代码
const bool useMock = true;

/// 初始化依赖注入
Future<void> configureDependencies() async {
  await _registerCore();
  _registerDataSources();
  _registerRepositories();
  _registerUseCases();
  _registerBlocs();
}

/// 注册核心基础设施
Future<void> _registerCore() async {
  // SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPreferences);

  // Hive - 注册 Adapter
  Hive.registerAdapter(CartItemHiveModelAdapter());
  // 打开购物车 Box
  final cartBox = await Hive.openBox<CartItemHiveModel>('cart_box');
  getIt.registerSingleton<Box<CartItemHiveModel>>(cartBox);

  // 拦截器
  getIt.registerFactory<AuthInterceptor>(
    () => AuthInterceptor(getIt<SharedPreferences>()),
  );
  getIt.registerFactory<LoggingInterceptor>(() => LoggingInterceptor());
  getIt.registerFactory<ErrorInterceptor>(() => ErrorInterceptor());

  // Dio Client（支持 Mock）
  getIt.registerLazySingleton<DioClient>(
    () => DioClient(
      authInterceptor: getIt<AuthInterceptor>(),
      loggingInterceptor: getIt<LoggingInterceptor>(),
      errorInterceptor: getIt<ErrorInterceptor>(),
      httpClientAdapter: useMock ? MockApiAdapter.instance : null,
    ),
  );
}

/// 注册 DataSource（数据层）
void _registerDataSources() {
  // ---------- Home ----------
  getIt.registerFactory<HomeRemoteDataSource>(
    () => HomeRemoteDataSource(getIt<DioClient>()),
  );

  // ---------- Cart ----------
  getIt.registerFactory<CartLocalDataSource>(
    () => CartLocalDataSource(getIt<Box<CartItemHiveModel>>()),
  );

  // ---------- Product Detail ----------
  getIt.registerFactory<ProductRemoteDataSource>(
    () => ProductRemoteDataSource(getIt<DioClient>()),
  );

  // ---------- Order ----------
  getIt.registerFactory<OrderRemoteDataSource>(
    () => OrderRemoteDataSource(getIt<DioClient>()),
  );

  // ---------- Auth ----------
  getIt.registerFactory<AuthLocalDataSource>(
    () => AuthLocalDataSource(getIt<SharedPreferences>()),
  );
  getIt.registerFactory<AuthRemoteDataSource>(
    () => AuthRemoteDataSource(getIt<DioClient>()),
  );
}

/// 注册 Repository（数据层）
void _registerRepositories() {
  // ---------- Home ----------
  getIt.registerFactory<HomeRepository>(
    () => HomeRepositoryImpl(getIt<HomeRemoteDataSource>()),
  );

  // ---------- Cart ----------
  getIt.registerFactory<CartRepository>(
    () => CartRepositoryImpl(getIt<CartLocalDataSource>()),
  );

  // ---------- Product Detail ----------
  getIt.registerFactory<ProductRepository>(
    () => ProductRepositoryImpl(getIt<ProductRemoteDataSource>()),
  );

  // ---------- Auth ----------
  getIt.registerFactory<AuthRepository>(
    () => AuthRepositoryImpl(
      getIt<AuthRemoteDataSource>(),
      getIt<AuthLocalDataSource>(),
    ),
  );

  // ---------- Order ----------
  getIt.registerFactory<OrderRepository>(
    () => OrderRepositoryImpl(getIt<OrderRemoteDataSource>()),
  );

  // ---------- Search ----------
  getIt.registerFactory<SearchRepository>(
    () => SearchRepositoryImpl(
      getIt<DioClient>(),
      getIt<SharedPreferences>(),
    ),
  );
}

/// 注册 UseCase（领域层）
void _registerUseCases() {
  // ---------- Home ----------
  getIt.registerFactory<GetBannersUseCase>(
    () => GetBannersUseCase(getIt<HomeRepository>()),
  );
  getIt.registerFactory<GetCategoriesUseCase>(
    () => GetCategoriesUseCase(getIt<HomeRepository>()),
  );
  getIt.registerFactory<GetRecommendProductsUseCase>(
    () => GetRecommendProductsUseCase(getIt<HomeRepository>()),
  );

  // ---------- Product Detail ----------
  getIt.registerFactory<GetProductDetailUseCase>(
    () => GetProductDetailUseCase(getIt<ProductRepository>()),
  );

  // ---------- Cart ----------
  getIt.registerFactory<GetCartUseCase>(
    () => GetCartUseCase(getIt<CartRepository>()),
  );
  getIt.registerFactory<AddToCartUseCase>(
    () => AddToCartUseCase(getIt<CartRepository>()),
  );
  getIt.registerFactory<UpdateQuantityUseCase>(
    () => UpdateQuantityUseCase(getIt<CartRepository>()),
  );
  getIt.registerFactory<ToggleSelectUseCase>(
    () => ToggleSelectUseCase(getIt<CartRepository>()),
  );
  getIt.registerFactory<ToggleSelectAllUseCase>(
    () => ToggleSelectAllUseCase(getIt<CartRepository>()),
  );
  getIt.registerFactory<RemoveCartItemUseCase>(
    () => RemoveCartItemUseCase(getIt<CartRepository>()),
  );
  getIt.registerFactory<GetCartCountUseCase>(
    () => GetCartCountUseCase(getIt<CartRepository>()),
  );
  getIt.registerFactory<ClearCartUseCase>(
    () => ClearCartUseCase(getIt<CartRepository>()),
  );

  // ---------- Auth ----------
  getIt.registerFactory<LoginUseCase>(
    () => LoginUseCase(getIt<AuthRepository>()),
  );
  getIt.registerFactory<LogoutUseCase>(
    () => LogoutUseCase(getIt<AuthRepository>()),
  );
  getIt.registerFactory<GetCurrentUserUseCase>(
    () => GetCurrentUserUseCase(getIt<AuthRepository>()),
  );

  // ---------- Order ----------
  getIt.registerFactory<GetOrderListUseCase>(
    () => GetOrderListUseCase(getIt<OrderRepository>()),
  );
  getIt.registerFactory<GetOrderDetailUseCase>(
    () => GetOrderDetailUseCase(getIt<OrderRepository>()),
  );
  getIt.registerFactory<CancelOrderUseCase>(
    () => CancelOrderUseCase(getIt<OrderRepository>()),
  );
  getIt.registerFactory<ConfirmReceiptUseCase>(
    () => ConfirmReceiptUseCase(getIt<OrderRepository>()),
  );

  // ---------- Search ----------
  getIt.registerFactory<SearchProductsUseCase>(
    () => SearchProductsUseCase(getIt<SearchRepository>()),
  );
  getIt.registerFactory<GetSearchHistoryUseCase>(
    () => GetSearchHistoryUseCase(getIt<SearchRepository>()),
  );
  getIt.registerFactory<SaveSearchHistoryUseCase>(
    () => SaveSearchHistoryUseCase(getIt<SearchRepository>()),
  );
  getIt.registerFactory<ClearSearchHistoryUseCase>(
    () => ClearSearchHistoryUseCase(getIt<SearchRepository>()),
  );
  getIt.registerFactory<GetHotKeywordsUseCase>(
    () => GetHotKeywordsUseCase(getIt<SearchRepository>()),
  );
}

/// 注册 Bloc（表现层）
///
/// 面试讲解点：
/// - 页面级 Bloc 使用 registerFactory（每个页面独立实例）
/// - 全局 Bloc 使用 registerLazySingleton（全 App 共享）
void _registerBlocs() {
  // ---------- Category (Singleton，切换 Tab 不重建，注册时加载一次) ----------
  getIt.registerLazySingleton<CategoryBloc>(
    () => CategoryBloc(getIt<GetCategoriesUseCase>())
      ..add(const CategoryLoaded()),
  );

  // ---------- Home (Singleton，全局共享，避免切换 Tab 重复加载) ----------
  getIt.registerLazySingleton<HomeBloc>(
    () => HomeBloc(
      getBannersUseCase: getIt<GetBannersUseCase>(),
      getCategoriesUseCase: getIt<GetCategoriesUseCase>(),
      getRecommendProductsUseCase: getIt<GetRecommendProductsUseCase>(),
    )..add(const HomeInitialEvent()),
  );

  // ---------- Product Detail (Factory，每次进入新页面新实例) ----------
  getIt.registerFactory<ProductDetailBloc>(
    () => ProductDetailBloc(getIt<GetProductDetailUseCase>()),
  );

  // ---------- Cart (Singleton，全局共享) ----------
  getIt.registerLazySingleton<CartBloc>(
    () => CartBloc(
      getCartUseCase: getIt<GetCartUseCase>(),
      addToCartUseCase: getIt<AddToCartUseCase>(),
      updateQuantityUseCase: getIt<UpdateQuantityUseCase>(),
      toggleSelectUseCase: getIt<ToggleSelectUseCase>(),
      toggleSelectAllUseCase: getIt<ToggleSelectAllUseCase>(),
      removeCartItemUseCase: getIt<RemoveCartItemUseCase>(),
      getCartCountUseCase: getIt<GetCartCountUseCase>(),
      clearCartUseCase: getIt<ClearCartUseCase>(),
    )..add(const CartLoaded()),
  );

  // ---------- Auth (Singleton，全局共享) ----------
  getIt.registerLazySingleton<AuthBloc>(
    () => AuthBloc(
      getCurrentUserUseCase: getIt<GetCurrentUserUseCase>(),
      logoutUseCase: getIt<LogoutUseCase>(),
    )..add(const AuthCheckStatus()),
  );

  // ---------- Login (Factory) ----------
  getIt.registerFactory<LoginBloc>(
    () => LoginBloc(getIt<LoginUseCase>()),
  );

  // ---------- Order List (Factory，每次进入新实例) ----------
  getIt.registerFactory<OrderListBloc>(
    () => OrderListBloc(getIt<GetOrderListUseCase>()),
  );

  // ---------- Order Detail (Factory，每次进入新实例) ----------
  getIt.registerFactory<OrderDetailBloc>(
    () => OrderDetailBloc(
      getOrderDetailUseCase: getIt<GetOrderDetailUseCase>(),
      cancelOrderUseCase: getIt<CancelOrderUseCase>(),
      confirmReceiptUseCase: getIt<ConfirmReceiptUseCase>(),
    ),
  );

  // ---------- Search (Factory，每次进入新实例) ----------
  getIt.registerFactory<SearchBloc>(
    () => SearchBloc(
      searchProductsUseCase: getIt<SearchProductsUseCase>(),
      getSearchHistoryUseCase: getIt<GetSearchHistoryUseCase>(),
      saveSearchHistoryUseCase: getIt<SaveSearchHistoryUseCase>(),
      clearSearchHistoryUseCase: getIt<ClearSearchHistoryUseCase>(),
      getHotKeywordsUseCase: getIt<GetHotKeywordsUseCase>(),
    ),
  );
}
