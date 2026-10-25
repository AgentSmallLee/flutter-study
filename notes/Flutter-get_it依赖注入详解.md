# get_it 依赖注入详解

> 问题：get_it 是什么？在当前项目中是怎么用的？

---

## 一、get_it 是什么？

`get_it` 是 Dart/Flutter 生态中最流行的**服务定位器（Service Locator）** 库，用来实现**依赖注入（Dependency Injection, DI）**。

> 💡 简单理解：get_it 就是一个**全局的"对象仓库"**——你提前把各种对象（数据库、网络客户端、Bloc、Repository 等）注册进去，需要用的时候直接 `getIt<类型>()` 取，不用自己 new、不用层层传递。

### 为什么需要依赖注入？

| 痛点 | get_it 怎么解决 |
|---|---|
| 对象创建到处都是 new，改一个构造函数要改很多地方 | 集中注册，改构造只改一处 |
| 单例写起来麻烦（懒加载、线程安全） | `registerLazySingleton` 一句话搞定 |
| 测试时不方便替换实现（Mock 困难） | 可以注册不同的实现，测试时替换为 Mock |
| 各层耦合严重（UI 直接 new Repository） | 依赖抽象接口，具体实现由 get_it 注入 |

### 版本信息

项目中使用版本：`get_it: ^7.7.0`（`pubspec.yaml` 第 21 行）

---

## 二、项目中的使用方式

### 核心文件

**`lib/core/di/service_locator.dart`** — 所有依赖的注册中心

```dart
final getIt = GetIt.instance;  // 全局单例
```

### 初始化时机

在 `main()` 函数中，`runApp` 之前完成初始化（`lib/main.dart` 第 32 行）：

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // ...
  await configureDependencies();  // ← 初始化所有依赖
  runApp(const MyApp());
}
```

### 注册顺序（从下往上，依赖方向）

```dart
Future<void> configureDependencies() async {
  await _registerCore();          // 1. 核心基础设施（Dio、SharedPreferences、拦截器）
  _registerDataSources();         // 2. 数据源层（Remote/Local DataSource）
  _registerRepositories();        // 3. 数据仓库层（Repository 实现）
  _registerUseCases();            // 4. 用例层（UseCase）
  _registerBlocs();               // 5. 表现层（Bloc）
}
```

> 💡 **注册顺序的原则**：先注册"被依赖的"，后注册"依赖别人的"。
> Bloc 依赖 UseCase，UseCase 依赖 Repository，Repository 依赖 DataSource，DataSource 依赖 DioClient。

---

## 三、三种注册方式对比

get_it 提供多种注册方式，项目中用到了三种：

| 注册方式 | 项目用法 | 特点 | 适用场景 |
|---|---|---|---|
| **`registerSingleton`** | SharedPreferences、Hive Box | 立即创建，全局唯一实例 | 必须提前初始化的对象 |
| **`registerLazySingleton`** | DioClient、HomeBloc、CartBloc、AuthBloc、CategoryBloc | 第一次使用时才创建（懒加载），全局唯一 | 重量级对象、全局状态 |
| **`registerFactory`** | DataSource、Repository、UseCase、ProductDetailBloc、LoginBloc、SearchBloc | 每次调用都创建新实例 | 页面级对象、用完即弃 |

### 项目中的具体应用

#### 1. registerSingleton — 立即创建的单例

```dart
// SharedPreferences 必须 await 初始化完才能用
final sharedPreferences = await SharedPreferences.getInstance();
getIt.registerSingleton<SharedPreferences>(sharedPreferences);

// Hive Box 同理
final cartBox = await Hive.openBox<CartItemHiveModel>('cart_box');
getIt.registerSingleton<Box<CartItemHiveModel>>(cartBox);
```

> 为什么用 `registerSingleton`？因为这些对象需要 `await` 初始化完成，不能懒加载。

#### 2. registerLazySingleton — 懒加载单例

```dart
// DioClient：全局只有一个网络客户端
getIt.registerLazySingleton<DioClient>(
  () => DioClient(
    authInterceptor: getIt<AuthInterceptor>(),
    loggingInterceptor: getIt<LoggingInterceptor>(),
    errorInterceptor: getIt<ErrorInterceptor>(),
    httpClientAdapter: useMock ? MockApiAdapter.instance : null,
  ),
);

// HomeBloc：全局单例，切换 Tab 不重建
getIt.registerLazySingleton<HomeBloc>(
  () => HomeBloc(
    getBannersUseCase: getIt<GetBannersUseCase>(),
    getCategoriesUseCase: getIt<GetCategoriesUseCase>(),
    getRecommendProductsUseCase: getIt<GetRecommendProductsUseCase>(),
  )..add(const HomeInitialEvent()),  // ← 注册时就触发首次加载！
);
```

> 为什么 HomeBloc 用 lazySingleton？
> - 首页是 Tab 核心页面，切换 Tab 时不希望重新加载数据
> - 全局共享状态，多个地方可能用到
> - 懒加载：只有第一次进入首页时才创建，不影响启动速度

#### 3. registerFactory — 每次都新建

```dart
// 每个页面独立的 Bloc，每次进入新页面新建实例
getIt.registerFactory<ProductDetailBloc>(
  () => ProductDetailBloc(getIt<GetProductDetailUseCase>()),
);

// DataSource、Repository、UseCase 也都是 factory
getIt.registerFactory<HomeRemoteDataSource>(
  () => HomeRemoteDataSource(getIt<DioClient>()),
);
getIt.registerFactory<HomeRepository>(
  () => HomeRepositoryImpl(getIt<HomeRemoteDataSource>()),
);
getIt.registerFactory<GetBannersUseCase>(
  () => GetBannersUseCase(getIt<HomeRepository>()),
);
```

> 为什么这些用 factory？
> - 它们是"工具人"，每次使用创建新的也没关系
> - 避免长期持有引用导致内存泄漏
> - 页面级 Bloc 每次进入新页面应该是全新状态

---

## 四、项目中的使用场景

### 场景 1：BlocProvider 中获取全局 Bloc

`lib/app.dart` 第 27-29 行：

```dart
MultiBlocProvider(
  providers: [
    BlocProvider<AuthBloc>.value(value: getIt<AuthBloc>()),
    BlocProvider<CartBloc>.value(value: getIt<CartBloc>()),
  ],
  child: MaterialApp.router(...),
)
```

全局 Bloc 从 getIt 取，通过 `BlocProvider.value` 注入 Widget 树，所有子 Widget 都可以通过 `context.read<AuthBloc>()` 获取。

### 场景 2：页面中获取页面级 Bloc

`HomePage`（`lib/features/home/presentation/pages/home_page.dart` 第 36-37 行）：

```dart
BlocProvider.value(
  value: getIt<HomeBloc>(),
  child: Scaffold(...),
)
```

### 场景 3：构造函数注入（依赖链自动解析）

最典型的例子：HomeBloc 的创建

```dart
getIt.registerLazySingleton<HomeBloc>(
  () => HomeBloc(
    getBannersUseCase: getIt<GetBannersUseCase>(),  // ← 自动从 getIt 取
    getCategoriesUseCase: getIt<GetCategoriesUseCase>(),
    getRecommendProductsUseCase: getIt<GetRecommendProductsUseCase>(),
  ),
);
```

当你调用 `getIt<HomeBloc>()` 时，getIt 会：
1. 发现 HomeBloc 需要 `GetBannersUseCase`
2. 去 GetBannersUseCase 的注册工厂里取 → 发现它需要 `HomeRepository`
3. 去 HomeRepository 的注册工厂里取 → 发现它需要 `HomeRemoteDataSource`
4. 去 HomeRemoteDataSource 的注册工厂里取 → 发现它需要 `DioClient`
5. 去 DioClient 的注册里取 → 懒加载创建 DioClient
6. 一路返回，层层组装，最后返回完整的 HomeBloc

> 💡 这就是依赖注入的魅力——你只需要用 `getIt<HomeBloc>()`，一整条依赖链自动帮你建好。

---

## 五、项目中 Bloc 注册策略总结

| Bloc | 注册方式 | 原因 |
|---|---|---|
| `AuthBloc` | `registerLazySingleton` | 全局登录状态，路由守卫依赖 |
| `CartBloc` | `registerLazySingleton` | 全局购物车状态，底部导航徽标、商品详情多处共享 |
| `HomeBloc` | `registerLazySingleton` | 首页 Tab 切换不重建，避免重复加载 |
| `CategoryBloc` | `registerLazySingleton` | 分类 Tab 切换不重建 |
| `ProductDetailBloc` | `registerFactory` | 每次进入商品详情都是新页面新状态 |
| `LoginBloc` | `registerFactory` | 登录页每次进入新实例 |
| `SearchBloc` | `registerFactory` | 搜索页每次进入新实例 |
| `OrderListBloc` | `registerFactory` | 订单列表每次进入新实例 |
| `OrderDetailBloc` | `registerFactory` | 订单详情每次进入新实例 |

---

## 六、Mock 切换的巧妙设计

项目中有一个非常实用的设计——通过配置切换 Mock/真实环境：

```dart
const bool useMock = true;  // 开关

getIt.registerLazySingleton<DioClient>(
  () => DioClient(
    ...
    httpClientAdapter: useMock ? MockApiAdapter.instance : null,
  ),
);
```

通过替换 Dio 的 `httpClientAdapter`，不需要修改任何业务代码，就能在 Mock 数据和真实 API 之间切换。这就是依赖注入带来的好处——**对上层透明，底层可替换**。

---

## 七、一句话总结

> **get_it 是一个服务定位器库，用来实现依赖注入。项目中把所有对象（从 Dio、DataSource 到 Repository、UseCase、Bloc）都集中在 service_locator.dart 里注册，按"核心层 → 数据层 → 领域层 → 表现层"的顺序从下往上注册，用 singleton / lazySingleton / factory 三种方式管理生命周期，需要时通过 `getIt<类型>()` 获取，实现了解耦、便于测试、易于维护。**

---

## 相关文件索引

| 文件 | 作用 |
|---|---|
| `lib/core/di/service_locator.dart` | 依赖注入注册中心，所有依赖在这里注册 |
| `lib/main.dart` | App 入口，调用 `configureDependencies()` 初始化 |
| `lib/app.dart` | 根 Widget，从 getIt 获取全局 Bloc 注入 Widget 树 |
| `lib/features/home/presentation/pages/home_page.dart` | 页面中通过 `getIt<HomeBloc>()` 获取 Bloc |
