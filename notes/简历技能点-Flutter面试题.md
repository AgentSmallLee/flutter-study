# 简历技能点专项面试题(Flutter 开发)

> 依据 `简历.md` 专业技能「Flutter 开发」的 10 条逐条出题。面试官拿着你的简历,大概率就是照着这些关键词深挖——**简历上写的每一个词,都是你授权面试官提问的范围**。本文档每条技能包含:面试官考察意图、高频问题与参考答案、追问链、以及基于你项目(flutter_ecom)真实实现的话术。
>
> 姊妹篇:[Dart语言面试题大全.md](./Dart语言面试题大全.md)(语言基础)、[Flutter面试题大全.md](./Flutter面试题大全.md)(框架原理),重复的基础原理此处只做引用,重点讲"简历关键词"专属的深挖点。

---

## 目录

1. [Dart 语言:异步/Mixin/扩展方法/泛型](#一dart-语言异步mixin扩展方法泛型)
2. [框架原理:三棵树/生命周期/状态管理/渲染流程](#二框架原理三棵树生命周期状态管理渲染流程)
3. [flutter_bloc + Equatable 状态管理](#三flutter_bloc--equatable-状态管理)
4. [Clean Architecture 与 get_it 依赖注入](#四clean-architecture-与-get_it-依赖注入)
5. [Dio 网络封装 + dartz Either 错误处理](#五dio-网络封装--dartz-either-错误处理)
6. [go_router 声明式路由](#六go_router-声明式路由)
7. [混合开发:Module 集成/Engine 预热/MethodChannel/登录态共享](#七混合开发)
8. [Hive 与 SharedPreferences 选型](#八hive-与-sharedpreferences-选型)
9. [性能优化:列表/图片缓存/防抖/细粒度刷新](#九性能优化)
10. [UI 组件开发:自定义 Widget/主题/国际化/屏幕适配](#十ui-组件开发)
11. [针对简历的"压力测试"问题](#十一针对简历的压力测试问题)

---

## 一、Dart 语言:异步/Mixin/扩展方法/泛型

> 简历原文:"扎实掌握 Dart 语言,熟悉异步编程(Future/Stream)、Mixin、扩展方法、泛型等特性,具备良好的代码规范和可维护性意识"

### 考察意图

"熟悉 XX 特性"这种写法,面试官默认你 **能讲原理 + 能说出项目里的使用场景**。只背语法不够,必须每条都准备一个"我在 flutter_ecom 里怎么用的"。

### 1.1 Future 和 Stream 的区别?你在项目里分别用在哪?

- Future:单次异步结果(一次网络请求、一次 sp 读取);Stream:随时间推送的多值序列(状态流、事件流)。
- **项目话术**:数据层 Dio 请求返回 Future;而 flutter_bloc 的核心 `state` 本身就是一个 Stream——`BlocStream`,`BlocBuilder` 内部通过 `bloc.stream.listen` 订阅状态变化,所以我在路由守卫里用 `getIt<AuthBloc>().stream.listen` 让 go_router 感知登录态变化(`app_router.dart` 的 `_AuthStateListenable`)。这是"Stream 驱动 UI"的典型落地。

### 1.2 async/await 的原理?await 会阻塞线程吗?

不阻塞。`await` 挂起当前函数,把后续代码注册为恢复回调,控制权交回事件循环;isolate 继续处理其它任务。详见 Dart 面试题大全·第九节(事件循环/微任务队列)。

### 1.3 Stream 的单订阅和广播模式?flutter_bloc 用的是哪种?

- 默认单订阅 Stream(只能 listen 一次,支持背压 pause/resume);`StreamController.broadcast` / `asBroadcastStream` 支持多订阅、无背压。
- **项目话术**:Bloc 的 state stream 允许多个 BlocBuilder 订阅同一个 Bloc,底层 `BlocObserver`/`emitter` 用的是广播语义;订阅生命周期由框架管理(Widget 销毁时 `close()`)。
- 追问:**你们自己写过 StreamController 吗?怎么防泄漏?** 答:优先用 bloc/框架托管;自己写时一定 `StreamSubscription` 存字段,dispose 里 cancel,controller close。

### 1.4 Mixin 解决什么问题?项目里哪里用了?

- 单继承下的"多重复用"。对比 Java:没有默认方法的接口可用,只能装饰器或继承链,而 Dart mixin 可以横向复用行为。
- **项目话术**(务必准备,面试常问"你项目里用过吗"):
  - `SingleTickerProviderStateMixin` / `TickerProviderStateMixin`:让 State 提供 vsync 给 AnimationController;
  - 我在仓库混入方式封装的还有如 `TickerMode`、Flutter 内部大量 mixin(`AutomaticKeepAliveClientMixin`——列表页保持状态,配合 IndexedStack/PageView 让切换 tab 不重置列表位置)。
- 原理级追问:**mixin 线性化(从 with 列表最后往前找方法)、on 约束**,见 Dart 面试题大全·六-4。

### 1.5 扩展方法(Extension)了解吗?项目里怎么用的?

给已有类型无侵入添加方法,不产生继承关系、不修改源码:

```dart
// core/extensions/ 里我封装的典型例子:
extension ContextExt on BuildContext {
  ThemeData get theme => Theme.of(this);  // 缩短常用样板
}
extension DoubleExt on double {
  Widget get h => SizedBox(height: this); // 尺寸语法糖
}
```

- 优点:无侵入、可 tree-shake;缺点:不能被覆写、不能存字段(静态解析,通过 `on` 类型静态分发)。
- 追问:**扩展方法能被子类覆写吗?** 不能——编译期按"静态类型 + 扩展名"决议,没有虚分派。Dart 3.3+ 还有 `extension type`(零成本包装)。

### 1.6 泛型在项目里的实际应用?

- 网络层:`DioClient.get<T>` 泛型指定响应类型;仓储层 `Future<Result<List<OrderEntity>>>` 携带业务泛型;
- **`Either<Failure, T>` 的 `Result<T>` typedef**(项目里 `failures.dart`):把"成功或失败"类型化,这是函数式的泛型应用;
- `Box<CartItemHiveModel>` Hive 泛型 Box 保证类型安全;
- 追问:**Dart 泛型运行时可查(reified),与 Java 类型擦除的区别** —— 一定要能答,详见 Dart 面试题大全·七-1。

### 1.7 "良好的代码规范和可维护性意识"——能具体说说吗?(开放题,提前准备)

准备 3~4 个具体点(每点一句项目例证):
- **flutter_lints 严格化**,`prefer_const_constructors`、`avoid_print`(我们用 AppLogger 封装替代 print,支持分级/格式化);
- **常量统一管理**:Channel 名、方法名全部收敛到 `BridgeChannels`/`BridgeMethods` 常量类,杜绝魔法字符串(通道两端对齐);
- **不可变优先**:State 全部 Equatable + final 字段,变化靠 copyWith/emit 新实例;
- **分层边界**:presentation 不 import data 层,靠 GetIt 按抽象接口注入,靠 linter/目录约定约束。

---

## 二、框架原理:三棵树/生命周期/状态管理/渲染流程

> 简历原文:"深入理解 Flutter 框架原理,包括 Widget 树、Element 树、RenderObject 三棵树的关系、Widget 生命周期、状态管理机制及渲染流程"

### 考察意图

这行是简历上最"硬"的一句,面试官必然重点轰炸。完整原理答案见 [Flutter面试题大全.md](./Flutter面试题大全.md) 第二、三、四节,此处列出**针对你简历的问法**和必须达标的深度要求。

### 2.1 三棵树的关系 —— 标准答法(必须脱稿)

- Widget:不可变配置(蓝图);Element:实例化桥接 + diff 复用判断(BuildContext 即 Element);RenderObject:实际测量/布局/绘制;
- `setState` → 标脏 Element → 下一帧 build → Element 拿新 Widget 做 `runtimeType + key` 比对 → 复用则只更新 RenderObject 属性;
- 一句话总结:"**Widget 频繁重建、Element 尽量复用、RenderObject 尽量不动,这是 Flutter 高性能的根基**"。

### 2.2 结合项目讲三棵树的实际应用(高分答法)

- **`const` 构造跨过 diff**:MainShell 的 `_navItems` 定义为 `static const List`,整个底部导航是 const 子树,父级 rebuild 时直接复用,连 build 都跳过;
- **Key**:购物车列表删除中间项时 State 错位问题 → 列表 item 使用 ValueKey(购物车 item 用商品 id)保证 Element 按身份匹配,State 跟着数据走;
- **RenderObject 复用的边界**:同类型同 key 复用;`ProductDetailPage` 不同商品复用页面时通过 didUpdateWidget 重新加载——体现"Widget 配置变化但 Element 复用"。

### 2.3 Widget 生命周期在实际开发中的注意点(项目话术)

- `initState` 里只做订阅/初始化,我项目里页面级 Bloc 用 `MultiBlocProvider` 注入,bloc 的 `close()` 由 `BlocProvider` 自动管理(这是生命周期问题交给框架);
- **异步回来后 setState 防御**:统一 `if (!mounted) return`;
- 全局单例 Bloc(HomeBloc/CartBloc)不随页面销毁——所以它们的订阅(如 `_AuthStateListenable` 监听 AuthBloc)**必须在销毁路径手动 cancel**,我在 `dispose` 里处理,这是单例状态特有的生命周期问题。

### 2.4 渲染流程一句话达标版

VSync → UI 线程(build → layout → paint → 合成 LayerTree)→ Raster 线程光栅化 → GPU 上屏;两条流水线并行,一帧 16.6ms 里 UI/Raster 各约 8ms。细节(四线程、Impeller、animate tick)见 Flutter 面试题大全·第三节。

### 2.5 "状态管理机制"你简历和上一条并列写了,面试官可能问:框架自带的状态管理你了解哪些?

- `setState`(局部 State)、`InheritedWidget`(树下发,Theme/MediaQuery 的底层)、`ValueNotifier` + `ValueListenableBuilder`(轻量局部监听);
- 然后自然过渡:"这些组合起来就能覆盖多数场景,但大型项目需要更强的约束,所以我选了 flutter_bloc"——引到下一节。

---

## 三、flutter_bloc + Equatable 状态管理

> 简历原文:"熟练使用 flutter_bloc + Equatable 进行状态管理,掌握全局单例 Bloc 与页面级工厂 Bloc 的选型策略,能够基于状态机驱动 UI 构建"

### 考察意图

简历写得非常具体(单例/工厂、状态机),面试官 100% 会问选型理由和细节。**这节是你和其它候选人拉开差距的地方,要背熟到能画图。**

### 3.1 flutter_bloc 的核心概念:Event / State / Bloc / emit?

- **单向数据流**:`UI add(Event) → Bloc.on<Event> 处理 → emit(State) → BlocBuilder 重建 UI`;
- Cubit 是 Bloc 的简化版(没有 Event,直接方法调用 + emit),小状态用 Cubit,需要"可追溯事件流"用 Bloc;
- **项目话术**:"我的页面级状态用完整 Bloc(Event 可审计,配合 BlocObserver 打 transition 日志);简单计数类用 Cubit 也能收敛"——展示你知道两者的取舍而不是无脑用。

### 3.2 Bloc 的原理?BlocBuilder 怎么知道该重建?(深挖题)

- Bloc 继承自 `BlocStream`/`Stream`:`emit` 把新 state 广播到 stream;
- `BlocBuilder` 内部是一个 `StreamBuilder`:订阅 `bloc.stream`,每收到新 state 调 `buildWhen` 判断(默认直接重建)后执行 builder;
- **BlocProvider 本质是 `SingleChildStatefulWidget` + InheritedWidget**:把 bloc 实例放进树,子树 `context.read<T>()` 取;**页面级 BlocProvider 在 dispose 时自动 close** —— 所以工厂 Bloc 不会泄漏,这个设计要能讲出来;
- 追问:**context.read 和 context.watch 区别?** read 一次性取出不订阅(事件回调里用),watch 建立依赖(build 里用)。flutter_bloc 的 `BlocProvider.of` 默认 read 语义,重建依赖靠 builder 订阅。

### 3.3 为什么状态要继承 Equatable?不加会怎样?(简历点名,必考)

- flutter_bloc 的 `emit` 有**去重机制**:`if (state == emitted) 不广播`。默认 `==` 是身份比较,新 new 出来的 State 实例永远 `!=` 旧实例 → 每次都广播;
- 继承 Equatable → 值比较(按 props 字段)→ **状态没实质变化时跳过重建**,这是性能优化,也是"不可变状态"的配套;
- **项目话术**:"我所有 State 都继承 Equatable,把变化字段放 props,比如 `CartLoaded extends Equatable { items, totalPrice }`,items 内容不变时增删选中状态不触发列表整体重建"。

```dart
class CartLoaded extends CartState {
  final List<CartItem> items;
  const CartLoaded(this.items) : super.props([items]);
}
```

- 追问:**Equatable 的 == 对 List 怎么比较?** Deep equality(DeepCollectionEquality 递归比较元素),所以 list 内容级相等即可;**陷阱**:props 里放 Stream/Future 等不可值比较对象会退化。

### 3.4 全局单例 Bloc 和页面级工厂 Bloc 的选型策略?(简历原话,必考!)

你的 `service_locator.dart` 注释就是答案,整理成话术:

| | registerLazySingleton(全局) | registerFactory(页面级) |
|---|---|---|
| 适用 | **跨页面共享的状态**:登录态(AuthBloc)、购物车角标(CartBloc)、首页缓存(HomeBloc)、分类(CategoryBloc) | **页面私有状态**:商品详情(ProductDetailBloc)、订单列表/详情、搜索、登录(LoginBloc) |
| 生命周期 | App 级,不 close | 随页面创建/销毁(BlocProvider 自动 close) |
| 注册时机 | **惰性注册**:首次 getIt<T>() 才创建,创建即 add 初始事件(`..add(HomeInitialEvent())`) | 每次取用都新建实例,互不干扰(两个商详页并存各自的状态) |

- **为什么 HomeBloc 用单例?** 底部导航切 tab 时 ShellRoute 保留子树,如果用 Factory 每次进入重建都重新请求;单例 + `..add(InitialEvent)` 首次加载后切 tab **秒显缓存数据**,类似"内存级页面缓存"。
- **为什么 ProductDetailBloc 用 Factory?** 同一个页面会存在多个实例(两个不同商品的详情页同时入栈),状态必须隔离;且详情页退出即销毁,不留内存。
- **CategoryBloc 为什么单例?** 分类数据 App 全程不变,注册时加载一次,任何入口进入分类页都不重复请求。
- 追问①:**单例 Bloc 的内存泄漏风险?** 它持有 UseCase→Repository→DataSource 链,DataSource 持有 Dio/Box,这些都是单例基础设施,本来常驻;真正的订阅(比如我对 AuthBloc.stream 的路由监听)必须在路由器销毁时 cancel。
- 追问②:**页面级 Bloc 在 getIt 里注册成 Factory,那 BlocProvider 又是怎么销毁它的?** 页面在 Widget 树里用 BlocProvider(create: ...) 时框架自动 close;我项目用 `BlocProvider(create: (_) => getIt<T>())` 模式,create 闭包每次执行都从 getIt 取新工厂实例,销毁仍由 BlocProvider 负责。

### 3.5 "状态机驱动 UI"具体是什么意思?(简历原话,容易被打)

- UI 永远是 state 的纯函数:每一种界面形态 = 一种 State 类型,不散落 if/else;
- **项目话术**(order_list_state 为例):状态不是"数据 + loading 布尔",而是**互斥的状态类型**:

```dart
abstract class OrderListState extends Equatable {}
class OrderListInitial extends OrderListState {}
class OrderListLoading extends OrderListState {}
class OrderListLoaded extends OrderListState { final orders; final hasMore; }
class OrderListError extends OrderListState { final Failure failure; }
```

UI 侧 `BlocBuilder` 里 switch/模式匹配各状态分别渲染 Loading/列表/错误页——**非法状态不可表示**(比如"loading 且有数据"这种矛盾状态在类型系统层面就不存在),这是 MVI 思想在 bloc 里的落地。
- 追问:**和 Android 的 MVI 对比?** 你可以直说:这套"单一数据源 + 不可变状态 + 状态类型化 + 单向流"和 MVI(如 Orbit/MviKotlin)思想同源,我迁移过来很自然。—— 这是你 Android 背景的加分迁移点。

### 3.6 BlocObserver 是什么?你用在哪?

- 全局钩子:onCreate/onEvent/onChange/onTransition/onError/onClose;
- **项目话术**:`AppBlocObserver` 在 main 里 `Bloc.observer = AppBlocObserver()`,debug 模式打印 transition(事件→状态迁移)用于排查,release 用于错误上报、埋点(状态到达率统计)。这是"横切关注点不侵入业务"的实践。

### 3.7 为什么选 flutter_bloc 而不是 Provider/Riverpod/GetX?(必考选型题)

准备三层回答:
1. **团队/工程视角**:bloc 强约束(Event-Driven,状态迁移可审计),新人不会写出"随处改状态"的代码;BlocObserver 统一日志/上报,Riverpod 的自由度在大团队里反而难规范;
2. **测试视角**:纯 Dart 类不依赖 Widget,`blocTest` 直接测事件→状态序列;
3. **诚实加分**:"Riverpod 在异步、编译期安全上更现代,如果新项目无历史包袱我也会评估;GetX 全家桶我不选,状态/路由/DI 耦合太深,大项目难维护"。—— 展示你是有判断的选型者,不是只会用一样。

---

## 四、Clean Architecture 与 get_it 依赖注入

> 简历原文:"具备 Clean Architecture 架构设计与落地经验,熟练进行 data/domain/presentation 三层分层,使用 get_it 实现依赖注入,保障模块解耦与可测试性"

### 4.1 你的三层怎么划分?各层放什么?(拿着项目讲)

```
lib/
├── core/           # 跨 feature 的基础设施
│   ├── di/         # get_it 注册中心 service_locator.dart
│   ├── network/    # DioClient + interceptors + base_response
│   ├── error/      # Failure 体系
│   ├── router/ bridge/ extensions/ widgets/ ...
└── features/       # 业务模块(order / cart / auth / home ...)
    └── order/
        ├── data/         # datasource(实现)+ repository 实现 + model
        ├── domain/       # entity(纯业务对象)+ repository 抽象 + usecase
        └── presentation/ # bloc / page / widgets
```

- **domain**:纯 Dart,不 import Flutter/dio —— 只有 entity、repository **抽象接口**、usecase;
- **data**:抽象的落地(remote/local datasource)+ model(entity 的可序列化形态);
- **presentation**:bloc + 页面,只认识 domain。
- 依赖方向:**presentation → domain ← data**(依赖倒置,data 实现定义在 domain 的接口)。

### 4.2 为什么要 Entity 和 Model 两个类?(高频质疑)

- **Entity**(domain):纯业务对象,不知道 JSON/Hive 存在;
- **Model**(data):`fromJson/fromMap`/Hive TypeAdapter,可携带与服务端字段一一对应的冗余字段;
- 嚣张加分答法:"这个成本可以按页面降级——简单页面 Model 直接实现 Entity 接口或 Model extends Entity 减少重复;但**跨层污染的代价比样板代码大**,服务器改字段名只影响 data 层,这是我坚持分层的理由"。
- **项目例证**:OrderEntity(domain)vs OrderModel(data),Hive 侧还有 CartItemHiveModel —— 三层对象各服务一种"序列化边界"。

### 4.3 UseCase 层是不是过度设计?(必被质疑,准备防御)

标准答法:
- 单一职责一个用例一个类,依赖声明清晰(构造参数即依赖清单);
- 撮合/复用:`GetCartCountUseCase` 同时被购物车页和底部导航角标使用,业务规则"角标只算选中商品"只写一次;
- 可测试:mock repository 即可测,不用起 Dio;
- **诚实版**:"纯转发的 UseCase(直接 return repository.xxx)在简单 CRUD 里确实像仪式,我的取舍是团队规范优先统一模板,后期加缓存/校验规则时有位置放"——比硬辩有效。

### 4.4 get_it 的 registerSingleton / registerLazySingleton / registerFactory 区别?你的选型?

| API | 创建时机 | 实例数 | 我项目里 |
|---|---|---|---|
| registerSingleton | 注册时立即创建 | 1 | SharedPreferences、Hive Box(async 初始化必须 eager,因为要在 main 里 await 好传给别人) |
| registerLazySingleton | 首次 getIt<T>() 取用时创建 | 1 | DioClient、全局 Bloc(HomeBloc/CartBloc/AuthBloc) |
| registerFactory | 每次取用都创建 | N | 拦截器、页面级 Bloc、DataSource/Repository/UseCase |

追问:**为什么 DataSource/Repository/UseCase 用 Factory 而不是单例?** 它们无状态(状态都在 Bloc 和 Box/SP 里),Factory 每次新建开销可忽略,换来"绝无共享可变状态"的确定性;真正有状态的(Bloc 单例)才是必须单例的地方。
再追问:**registerLazySingleton 与 Bloc 的配合为什么不用 registerSingleton?** eager 会在 main 里就创建所有全局 Bloc 并发初始事件,拖启动;lazy 让首页首帧构建取用 HomeBloc 时才创建并加载。

### 4.5 get_it 是服务定位器,不是 DI 容器——你怎么回应"它不是真 DI"的质疑?(高级题)

- 诚实答:get_it 是 Service Locator 模式,依赖靠主动 `getIt<T>()` 拉取,构造注入和运行时解耦它确实没做到(对比 injectable 的编译期生成);
- 但在我的架构里,**拉取只发生在两个边界**:main 初始化 + BlocProvider 的 create 闭包,业务代码内不散落 getIt 调用,把 SL 的缺点控制到最小;
- 提一嘴 **injectable**(基于注解 + build_runner 自动生成注册代码)能消除手写 service_locator 的大文件,但会引入代码生成链路,团队当时选择手写集中管理。

### 4.6 "保障模块解耦与可测试性"——具体怎么测?(被问到要有实物)

- Repository 接口在 domain,测试里注入 FakeRepository(手写假实现或 mocktail),`blocTest('加载订单', build: () => OrderListBloc(fake), act: (b) => b.add(Load()), expect: [Loading(), Loaded()])`;
- 网络 Mock:**项目里 `MockApiAdapter` 替换 Dio 的 HttpClientAdapter**(useMock 常量切换),不用改任何业务代码就能脱离后端开发——把"可测试性"用架构真实落地,这句话面试官很吃;
- get_it 支持 `getIt.reset()`,单测之间隔离。

---

## 五、Dio 网络封装 + dartz Either 错误处理

> 简历原文:"熟练使用 Dio 进行网络请求封装,掌握拦截器链(Auth/Logging/Error)的设计与实现,结合 dartz 的 Either 进行函数式错误处理,统一异常治理"

### 5.1 你的拦截器链怎么设计的?顺序为什么是 Auth → Logging → Error?(简历原话,必考)

Dio 拦截器是**责任链**:
- 请求阶段(onRequest)按**添加顺序**执行;
- 响应/异常阶段(onResponse/onError)按**逆序**执行。

```dart
_dio.interceptors.addAll([authInterceptor, loggingInterceptor, errorInterceptor]);
```

- **Auth 放最前**:加 token 的动作要在 Logging 记录**之前**完成,日志才能记到带 token 的最终请求头;
- **Error 放最后**:onError 逆序第一个到达,统一把 DioException 转成 Failure 体系;
- **Logging 居中**:请求方向记录"已加签请求",响应方向在 Error 处理**之前**记录原始错误。
- 能把"顺序与方向"讲清,这题就赢了,很多人只知道加拦截器不知道为什么这么排。

### 5.2 Auth 拦截器怎么实现?token 过期怎么办?

- `onRequest` 从 SharedPreferences 读 token 塞 header;
- 401 处理:**方案 A** Error 拦截器捕获 UnauthorizedFailure,发全局事件让 AuthBloc 跳登录页(配合我路由的 `refreshListenable`);**方案 B(无感刷新)** 刷新 token 后用 `handler.resolve(response)` 重放请求;
- 并发陷阱(高级追问):多个请求同时 401 只能刷一次 —— 用共享的 `Completer<void> refreshLock`,第一个请求负责刷新,其它 await 同一个锁。

### 5.3 为什么用 Either 而不是 try/catch?这不是更麻烦吗?(简历点名,必考,备好辩论)

- 异常的问题:错误路径藏在签名外,调用方**可以不 catch,错误直接炸到运行时**;
- `Either<Failure, T>` 把失败放进**返回类型**:编译器逼你在编译期就处理 Left/Right 两条路径——错误"不可能被忽略";

```dart
typedef Result<T> = Either<Failure, T>;   // failures.dart

// repository:
Future<Result<List<Order>>> getOrders() async {
  try {
    final res = await remote.fetchOrders();
    return Right(res.map(OrderModel.fromJson).toList());
  } on DioException catch (e) {
    return Left(FailureMapper.map(e));   // 统一映射 ServerFailure/NetworkFailure/UnauthorizedFailure
  }
}

// bloc 里:
final result = await getOrdersUseCase();
result.fold(
  (failure) => emit(OrderListError(failure)),
  (orders) => emit(OrderListLoaded(orders)),
);
```

- **"统一异常治理"话术**:错误在 data 层**一次转换**(任何异常→Failure),domain/presentation 只面对类型化的 Failure(BusinessFailure 带 code、NetworkFailure 有默认文案),UI 只做"错误页/Toast 映射",错误处理路径全链路类型安全、可测试。
- 追问:**dartz 的 fold/map 是什么?** Either 是函数式代数数据类型,fold 处理两分支,map 只映射 Right(成功)分支;还可以提 sealed class + Dart 3 模式匹配是官方方向(dartz 已停止维护,新项目可自写 Result 类型),显示你对生态的清醒。

### 5.4 BaseResponse 统一包装怎么处理 code != 200?

- 后端包一层 `{code, message, data}`:Error/业务拦截或 Repository 里统一判断 code,非成功 → `Left(BusinessFailure(message, code))`;
- 关键点:**HTTP 200 但业务失败**也走 Failure 路径,不让"成功状态里的错误"漏到 UI。
- 追问:**data 泛型反序列化怎么做的?** `BaseResponse<T>.fromJson(json, (json) => T.fromJson(json))` 需要显式传fromJson 工厂(Dart 运行时拿不到泛型构造),或者手写 fromJson(我项目选择手动 fromJson 并在 pubspec 注释了 json_serializable 的取舍)。

### 5.5 Dio 还封装了什么?

- BaseOptions 统一 baseUrl/三个超时(连接/接收/发送)/默认 header;
- CancelToken 暴露到 UseCase 层,页面 dispose 取消未完成请求(可以和"页面退出后 setState 防御"串起来);
- **HttpClientAdapter 可替换**:MockApiAdapter 换适配器即整包 Mock,业务零改动 —— 这个设计点能讲 2 分钟,很能体现架构能力。

---

## 六、go_router 声明式路由

> 简历原文:"熟悉 go_router 声明式路由,掌握 ShellRoute 嵌套导航、路由守卫、路径参数传递、深链接等能力,能够搭建完整的应用导航体系"

### 6.1 声明式路由和 Navigator 1.0 的本质区别?

- 1.0 命令式:push/pop 修改一个黑盒栈,栈状态藏在框架里,难对接 deep link/系统返回/恢复;
- go_router:**当前 URL/location 是状态**,UI = f(location)。浏览器地址栏、`adb shell am start -d`,App Links 统一变成"改变 location 然后重建路由树",所以天生支持深链接。

### 6.2 ShellRoute 是什么?解决什么问题?(简历点名)

- **一个共享的"外壳"包住多个子路由**:我的 MainShell(底部导航 + 内容区)包住 home/category/cart/profile 四个 tab;
- 关键性质:**在 shell 内切换 tab,外壳不重建**(底部导航状态、动画不闪),且每个 tab 保留独立导航栈(shell 自己的 NavigatorKey);
- `parentNavigatorKey: _rootNavigatorKey` 让 login/商详/订单页**跳出 shell 全屏显示**(登录页不能带底部导航)—— 这个参数的用法是 go_router 熟练度的标志;

```dart
ShellRoute(
  builder: (context, state, child) => MainShell(child: child),  // 外壳
  routes: [/* 4 个 tab */],
),
GoRoute(path: '/login', parentNavigatorKey: _rootNavigatorKey, ...),
```

- 追问:**IndexedStack + Navigator 做底部导航 vs ShellRoute 的取舍?** ShellRoute 提供 URL 可寻址(分享/深链直达 tab)、状态恢复,IndexedStack 实现简单但页面不可寻址;混合开发里宿主要求"路由可被原生侧驱动"时 URL 化是刚需。

### 6.3 路由守卫(redirect)怎么实现的?(简历点名)

```dart
GoRouter(
  redirect: (context, state) {
    final loggedIn = getIt<AuthBloc>().state is AuthAuthenticated;
    final isLogin = state.matchedLocation == '/login';
    if (!loggedIn && !isLogin) return '/login';
    if (loggedIn && isLogin) return '/home';
    return null; // null = 不拦截
  },
  refreshListenable: _AuthStateListenable(), // 登录态变化时重新评估 redirect
)
```

三个高频追问:
1. **redirect 什么时候被评估?** 每次导航/URL 变化;
2. **登录态变化怎么主动触发重定向?** `refreshListenable`:我传了一个监听 `AuthBloc.stream` 的 ChangeNotifier,AuthBloc emit 新状态 → notifyListeners → go_router 重新跑 redirect → 未登录用户无论点哪都被弹回登录页。**这是把 bloc 和声明式路由打通的关键设计**,必须能脱稿讲;
3. **redirect 里能 push 吗?** 只 return 目标 location,不要在 redirect 里做副作用(会循环)。

### 6.4 路径参数、query 参数、extra 三种传参方式与选型

```dart
GoRoute(
  path: '/product/:id',                       // 路径参数:可寻址资源
  builder: (c, s) => ProductDetailPage(productId: int.parse(s.pathParameters['id']!)),
)
// query: /orders?status=2 → s.uri.queryParameters['status'] 适合筛选态
// extra: context.push('/order', extra: orderId) 复杂对象,但**不参与 URL,深链恢复会丢**
```

- 选型原则:**能进 URL 的进 URL**(分享/深链/恢复友好),只有临时大对象才用 extra,并做好 null 兜底。
- 追问:**参数用基本类型还是 entity?** 基本类型——URL 序列化边界外的东西用 extra 并防御 null(冷启动恢复时 extra 为空)。

### 6.5 深链接(deep link)怎么落地?

- Android:`AndroidManifest` 配 `VIEW intent-filter`(appLinks),系统把 URL 交给 Flutter,go_router 按 location 匹配;
- 混合开发场景(必追问):**Flutter 只是宿主 App 的一个模块**,deep link 进来是先到原生——原生解析 URL 决定"开原生页 or 进 Flutter 页并 push 对应 location",通过 MethodChannel 把 location 传给缓存的 Engine 再 `router.go()`。你的项目正好有这个链路,照 android_ecom 的 SplashActivity → Flutter 的流程讲。

### 6.6 go_router 你踩过什么坑?(真实感题)

准备两个:① ShellRoute 里用 `context.go` 切 tab 而不是 push(go 会**清栈替换**导致 shell 外层重建,正确做法是 tab 用 go、push 详情页用 `context.push`);② `NoTransitionPage` 让 tab 切换无转场动画,默认 Material 转场在底部导航上很怪。

---

## 七、混合开发

> 简历原文:"熟悉 Flutter 混合开发技术栈,掌握 Flutter Module 多仓集成模式、FlutterEngine 预加载与缓存、MethodChannel 原生桥接封装、登录态共享等核心方案,具备 Android 原生视角下的混合开发落地经验"

### 考察意图

这是你**区别于纯 Flutter 候选人的最大优势**,而且你有 android_ecom 宿主项目可讲。面试官会验证你是不是真的落地过(而不是看了两篇文章)。详细原理见 [Flutter面试题大全.md](./Flutter面试题大全.md) 第十五节,这里给"落地叙事"。

### 7.1 Flutter Module 多仓集成模式讲一下(简历点名)

- `flutter create --template module flutter_ecom` 生成 module,产出 `.android` 的**可被宿主 include 的 aar 源**;
- 宿主 `android_ecom` 的 `settings.gradle` 用 `includeBuild`/binding 引入 module 的 SDK,Gradle 同步后宿主直接依赖 Flutter 产物(你的项目就是这么组织的,可以现场讲 settings.gradle 的写法);
- 两种集成形态:**源码集成**(开发期,改 Flutter 代码宿主立即可见)vs **aar 集成**(release/团队协作,Flutter 团队单独出包,原生 Maven 依赖)——对比优劣:aar 隔离好但联调慢,源码集成快但要求每个人本机有 Flutter 环境,团队大了要走 aar + CI。
- Android 视角话术:"这就是把 Flutter 当成一个'带 Gradle 插件的特殊 library',和我做组件化时管理业务 module 的心智模型一致"。

### 7.2 FlutterEngine 预加载与缓存(简历点名,必考"为什么白屏/秒开")

标准流程 + 你的落地:

```kotlin
// Application/Splash 阶段预热:
val engine = FlutterEngine(context)
engine.dartExecutor.executeEntrypoint(DartEntrypoint(findAppBundlePath(), "main"))
FlutterEngineCache.getInstance(context).put("ecom_engine", engine)

// 跳转时:
startActivity(FlutterActivity.withCachedEngine("ecom_engine").build(context))
```

- **为什么要预热?** 冷启动 Engine 要:起 Dart VM → AOT 加载 → 执行 main → 首帧 build/layout/paint,首次进入 300ms~1s 白屏;
- **预热三件套**:Application 里尽早 create Engine(不用等用户点)、executeEntrypoint 让 Dart 先跑起来(可以首帧前做数据预取)、SplashActivity 挡住等待时间——**你的 SplashActivity + splash_background.xml 正是这个方案**,照着讲"我把预热藏在启动页里,用户感知不到引擎初始化";
- 追问①:**Engine 缓存的生命周期?** App 级,谁创建谁管理;内存敏感时 `engine.destroy()` 释放(每个 Engine ~几十 MB,绝不随意多开);
- 追问②:**预热会不会拖慢 App 启动?** 权衡:Application 里 create 是异步/低优先级的,主线程只做注册;首帧真正的依赖是 Engine 初始化完成,所以放 Splash(本来就有一段不可交互时间)消化它。

### 7.3 MethodChannel 桥接封装的完整叙事(简历点名)

照你的 `NativeBridge`/`FlutterBridgeManager` 讲设计决策:

1. **通道与方法名常量化**:`BridgeChannels`/`BridgeMethods` 统一管理(包名 + 功能名前缀防冲突),原生与 Dart 两端对齐,杜绝魔法字符串;
2. **单例封装**:业务层只见 `NativeBridge()` 的类型化方法(`getToken()`/`showToast()`),不接触 MethodChannel——异常、日志、参数校验统一收口;
3. **异常统一治理**:`on PlatformException` 捕获 → AppLogger 记录 → 返回 null/降级(桥接失败不能让 Flutter 页崩);
4. **为什么不用插件形式?** 你的注释就是答案:插件适合通用能力(camera),业务 Bridge 与宿主强耦合,统一放一处便于和原生同学对协议;
5. 原生侧:`FlutterBridgeManager : MethodChannel.MethodCallHandler`,`onMethodCall` 按 method 分发,`result.success/notImplemented/error` 三态返回(强对比 Kotlin 侧的密封结构)。

### 7.4 登录态共享方案(简历点名,必考)

混合开发的经典痛点:**用户在原生层已登录,Flutter 模块怎么知道?**

- 方案:**MethodChannel 拉取 + 事件推送结合**
  - Flutter 启动/需要时 `getToken()/nativeLogin()` **拉**原生 token 与用户信息;
  - 原生 token 刷新/登出时通过同通道 **推**(Dart 端 `setMethodCallHandler` 监听原生反向调用,或 EventChannel)更新 AuthBloc;
  - AuthBloc(全局单例)持有登录态,路由 `refreshListenable` 联动 —— **完整链路:原生 SP → MethodChannel → AuthBloc → go_router redirect**,这条链你能画出来,面试官就知道你是真做过的;
- 追问:**token 过期由谁判断?** 双向都可能:Flutter 网络层 401(UnauthorizedFailure)→ 通知原生刷新或跳原生登录;原生刷新后推新 token 给 Flutter,下次请求生效。要说明"**单一数据源在原生侧**,Flutter 只做缓存与同步",避免双端状态打架。

### 7.5 混合开发的返回与页面栈

- Flutter 页面内返回:`SystemNavigator.pop()` 或我封装的 `navigateBack()` 通道让宿主 finish;
- 栈结构:宿主 Activity 栈里 FlutterActivity 是一页;Flutter 内部又有自己的 Navigator 栈 —— 返回键逐层先出 Flutter 内部栈再退 Activity;
- 深挖预告:**FlutterBoost 为什么存在?** 单 Engine 多容器(每个原生页挂一个 Flutter View),解决"Flutter 页面夹在原生页面中间"时多 Engine 内存爆炸的问题 —— 提一句即可展示视野。

---

## 八、Hive 与 SharedPreferences 选型

> 简历原文:"熟悉 Hive、SharedPreferences 等本地存储方案,了解各方案的适用场景与性能差异,能够根据业务需求合理选型"

### 8.1 两者的机制与性能差异?(必考)

| | SharedPreferences | Hive |
|---|---|---|
| 形态 | 平台原生 KV(Android XML/GES 的二进制) | 纯 Dart NoSQL KV(Box) |
| 读取 | **启动首次 getInstance 全量载入内存**,后续读同步 | openBox 时载入,读内存同步,写异步 append |
| 写入 | apply 异步/commit 同步 | append-only 二进制日志,写入快 |
| 值类型 | 基本类型 + String(JSON 手动) | 基本类型 + 任意对象(**TypeAdapter**) |
| 加密 | 无(可结合 secure_storage) | HiveAesCipher 加密 |
| Web 支持 | 有 | 有 |

- 关键差异一句话:**Hive 支持对象级存储(带 TypeAdapter),sp 只能扁平 KV;Hive 写是 append 快,sp 是全文件重写**。

### 8.2 你的项目怎么选型的?(简历"合理选型"的落地)

- **SharedPreferences → 轻量配置与 token**:登录态、搜索历史这类小字符串(KV 简单、无需 schema);
- **Hive → 购物车**:对象级(CartItemHiveModel)、需要增删改查(单 item 修改只写单 key,不像 sp 全量)、离线可用的业务数据;
- `Hive.openBox<CartItemHiveModel>('cart_box')` 注册为单例,DataSource 直接注入 Box —— **存储选型参与 Clean Architecture 分层**:CartLocalDataSource 只认 Box,repository 不知道存储介质,日后换 Isar 只改 data 层。

### 8.3 Hive 的 TypeAdapter 是什么?为什么你手动实现?(项目细节题)

- TypeAdapter = 对象 ↔ 二进制的编解码器(类似 Parcelable),官方用 hive_generator 生成;
- **你项目的真实坑**:hive_generator/bloc_test 与当时的 Flutter 版本依赖冲突,我手动实现了 CartItemHiveModelAdapter(read/write 逐字段按序编解码)——这个"为了依赖健康宁可手写 60 行样板"的决策,比"我都会用生成器"更有说服力,照实讲;
- 字段顺序敏感性:手动 Adapter 的 read 必须与 write 字段顺序严格一致,加字段只能 append,不能插中间(老数据反序列化错乱)——这是手动实现的代价,能主动说出来是加分项。

### 8.4 主线程卡顿与初始化时机

- sp 的 `getInstance()` 是异步的且**首帧内多次 await 会排队** → 我在 `main()` 里一次性 await 完注册单例(启动页消化),后续读取同步无开销;
- Hive 的 openBox 也是 async,同样集中在 `configureDependencies()`(`_registerCore`)里完成 —— **异步初始化统一收口在启动流程,业务代码里永远同步读取**,这是我在项目里定下的规矩,能体现工程素养。

---

## 九、性能优化

> 简历原文:"具备 Flutter 性能优化意识,掌握列表优化(ListView.builder/const 构造函数)、图片缓存(cached_network_image)、输入防抖、Widget 细粒度刷新等常用优化手段"

> 完整的性能优化体系(RepaintBoundary、光栅化、DevTools 排查)见 [Flutter面试题大全.md](./Flutter面试题大全.md) 第十七节,此处聚焦简历点名的四个手段的"项目级"讲法。

### 9.1 列表优化:ListView.builder + const 的具体收益?(简历点名)

- `builder`:按视口 + cacheExtent 惰性构建,千条数据也只 build 可见的几十条 —— 与 RecyclerView 视口复用同思想;
- **const**:整棵 const 子树 rebuild 时直接跳过 build/diff;常亮 UI(标题、tab、底部导航 `_navItems`)全部 const 化,`static const` 放类级避免每次 build 分配;
- 配套:`itemExtent` 固定行高跳过逐条 layout、item 提取成独立 StatelessWidget 让局部变化不扩散。
- 项目话术:"我的商品列表 item 拆到 widget 级,价格变化由 BlocBuilder 只包价格那个 Text,而不是整行重建"。

### 9.2 cached_network_image 的原理与坑?(简历点名)

- 原理:三级缓存 —— 内存(ImageCache 管理解码后的 ui.Image)→ 磁盘(HTTP 缓存/自定义 CacheManager)→ 网络;`Image.network` 只有内存级;
- 常考坑:
  ① **列表大图导致光栅线程压力** → `memCacheWidth/memCacheHeight` 限制解码尺寸(下载 1080p 图但列表只显示 100dp,不解码全尺寸);
  ② placeholder/fadeIn 提升观感;errorWidget 兜底;
  ③ ImageCache 上限(`maximumSizeBytes`)与滑动场景内存抖动。
- 深挖:**图片解码在哪个线程?** IO 线程解码,raster 线程上传纹理 —— 图片问题是 Raster 泳道超时的主力,这段能接上渲染管线知识,显功底。

### 9.3 输入防抖怎么实现的?(简历点名,现场手写级)

```dart
// 搜索框防抖:Timer 版(我项目 SearchBloc 里用 emit.forEach + debounce 的变体)
Timer? _debounce;
void onQueryChanged(String q) {
  _debounce?.cancel();
  _debounce = Timer(400.ms, () => add(SearchQueryChanged(q)));
}
// dispose 里 _debounce?.cancel() —— 必须主动说,这是考察闭包泄漏意识
```

进阶答法(flutter_bloc 惯用法):**event transformer + stream 转换**:

```dart
@override
Stream<Transition<SearchEvent, SearchState>> transformEvents(
  Stream<SearchEvent> events, transitionFn) {
  return events
    .debounceTime(300.ms)             // rxdart
    .switchMap((e) => transitionFn(e)); // 取消旧请求,防止竞态乱序
}
```

- **switchMap 讲清"竞态"**:用户先输"a"再输"ab",前一个请求慢后一个快,"a"的结果后到会覆盖"ab" —— switchMap 只保留最新流,这是防抖之外真正的价值。**能讲出"防抖+switchMap 防竞态"两层,这题直接满分**。

### 9.4 Widget 细粒度刷新你落了什么手段?(简历点名,项目里有实证)

这是你项目的亮点,四级递进背下来:

1. **BlocSelector**(核心实证):底部导航购物车角标用 `BlocSelector<CartBloc, CartState, int>(selector: (s) => s.totalCount)` —— 购物车选中状态、总价变化**不会**触发底部导航重建,只有数量变化才重建角标那一个小 Stack;因为底部导航是全局常驻组件,压它的重建次数收益最大;
2. **buildWhen/ BlocBuilder 收窄**:`buildWhen: (prev, next) => prev.orders != next.orders` 只在关注字段变化时重建;
3. **Equatable 去重**(串联 3.3):emit 相等状态直接不广播,源头减排;
4. **粒度拆分**:BlocBuilder 只包变化的最小 Widget(价格 Text),而不是整页。
- 面试金句:"我的优化顺序是**先减少重建范围(粒度),再减少重建次数(去重),最后才考虑重绘层(RepaintBoundary)**"。

---

## 十、UI 组件开发

> 简历原文:"熟悉 Flutter UI 组件开发,掌握自定义 Widget、组合组件、主题定制、国际化、屏幕适配等能力,能够独立完成复杂交互页面的开发"

### 10.1 "自定义 Widget"你的理解与项目实例?

三个层次(由浅入深):
1. **组合**(最常用):把现有 Widget 组合成业务组件 —— 我的 `_CartBadgeIcon`(Stack+Positioned+Container 组合角标)、订单卡片 `OrderCard`;
2. **自定义 RenderObject / CustomPainter**:Canvas 直绘(我的自定义画布场景、环形进度);
3. **封装平台行为**:`AndroidView` 包装原生能力。
- 设计习惯话术:"我写的业务组件全部 `const` 构造 + 参数用命名参数 + required,回调暴露成 `ValueChanged<T>` 而不是具体控制器,保证组件无状态可复用"。

### 10.2 主题定制怎么做的?

- 单一 `ThemeData` 入口:`ColorScheme.fromSeed` 生成色板,MaterialApp lightTheme/darkTheme 双主题;
- 业务组件**永远 `Theme.of(context)` 取色,不写死 Color**(除非品牌色常量)→ 深色模式切换零成本;
- 局部覆写:`Theme` widget 包子树覆盖某个区域样式(购物车页的 Card 圆角统一)。
- Android 迁移话术:"这等价于我在原生里用 `attrs` + 主题 style 的中心化管理,但 Flutter 的 InheritedWidget 让主题变更自动触发依赖组件 rebuild,原生做不到这点"。

### 10.3 国际化(i18n)的落地?

- `flutter_localizations` + `.arb` 文件 + intl 包,`MaterialApp(localizationsDelegates / supportedLocales)`;
- 代码里 `AppLocalizations.of(context)!.orderTitle`;复数/日期用 intl 的 message 与 DateFormat;
- 混合开发追问:**App 的语言由谁定?** 原生跟随系统/用户设置,Flutter 侧 `MaterialApp.locale` 要与原生同步(通道拿宿主语言),否则模块内语言和宿主 App 打架 —— 结合你的混合项目讲是加分点。

### 10.4 屏幕适配你怎么做?对 ScreenUtil 类方案怎么看?(易踩坑的开放题)

- 我的实践:**布局优先用弹性方案**(Expanded/Flexible/MediaQuery 断点/LayoutBuilder),字号用 sp 语义配合系统字体缩放(`textScaleFactor` 可访问性),间距密度用少量常量;
- 对 **按设计稿等比缩放**(flutter_screenutil 375 基准):诚实评价——优势是还原设计稿快;劣势是破坏系统字体缩放的可访问性、大屏(平板/折叠屏)等比放大很怪、复杂多断点需要重新校对;
- 我的结论:"**以约束驱动为主、rpx 为辅**,平板适配必须走断点而不是等比" —— 这个立场比无脑吹 ScreenUtil 更专业。

### 10.5 "复杂交互页面"——举一个你做过的(提前准备故事)

备一个完整叙事(SPA 结构:背景→方案→难点→量化结果),例如购物车页:多选/全选/角标/数量步进/合计实时计算,交互状态多 → 状态机建模(单一 CartBloc,State 类型化)、角标细粒度刷新、Hive 离线持久化、删除项的 key 稳定性问题(ValueKey)——把这个页面从 UI 到状态到存储串成一条线,能应对几乎所有"讲讲你的项目"的展开。

---

## 十一、针对简历的"压力测试"问题

面试官对"简历写得漂亮"的候选人,常用质疑型问题验证真实性。逐条准备:

### 11.1 "你说'深入理解',那我考你一个:"(原理抽查)

- setState 后 build 是立即执行吗?(不是,标脏 + 等 VSync 排帧,一帧内多次 setState 合并成一次 build)
- Element 什么时候会被销毁而不是复用?(runtimeType 或 key 不同 → 卸载;deactivate 后 GC 前有 GlobalKey 可捞回)
- 两个 Future 的 then 回调和微任务怎么排队?(已完成 future 的 then 进微任务,详见 Dart 面试题·十三)
- 加分回应策略:答不上的坦然说"这个细节我记得结论是 X,推导过程我下来确认",比硬编好。

### 11.2 "你项目是不是太'模板化'了?Clean Architecture + bloc 对这个体量是不是过度设计?"

标准防御:承认 trade-off,强调**约束的收益是团队性的**(多人协作、长期维护、mock 测试),同时展示弹性:"我在简单页面确实会把 UseCase 退化、Model 直接复用 Entity,架构服务于业务而不是反过来"。**绝不要**把架构吹成完美无缺。

### 11.3 "为什么不用 Riverpod?为什么不用代码生成(json_serializable/freezed)?"

- Riverpod:见 3.7 的三层答法(团队约束 + 迁移成本 + 我了解它的优势);
- 代码生成:你项目有真实素材——hive_generator 与当时 Flutter 版本依赖冲突,所以 Adapter 手写、JSON 手动 fromJson;顺带说出代价与收益:"手写样板多但零构建链路依赖,团队当时优先构建稳定性;新项目依赖健康的话我会引入 build_runner"。

### 11.4 "你 pubspec 里 dio 5.x / go_router 14 / Flutter 3.4x,这些版本有坑吗?"

- 准备一个真实版本坑(你 android_ecom 的 README 里就有:Flutter 3.47 移除了 `flutter.compileSdkVersion` 扩展属性,shared_preferences_android 2.4.28 适配问题,导致我们锁了插件版本并自己维护了 third_party 下的 sqflite_android/shared_preferences_android 源码)——**这是极好的"我真的维护过工程"的证据**,主动讲出来;
- 引申能力展示:讲清"混编项目的版本三角约束(Flutter SDK ↔ 插件版本 ↔ 宿主 Gradle/Kotlin/AGP)"。

### 11.5 "混合开发你只做了 Android,iOS 侧谁做的?如果让你做 iOS 你怎么开始?"

诚实 + 展示方法论:"我是 Android 原生出身,iOS 侧由同事负责,但协议是我定义的(通道/常量对齐),Dart 与原生两侧我都能改。iOS 集成差异我知道在:Engine 预热在 AppDelegate、平台通道同一套 API、PlatformView 是 UIKitView 语义不同。方法论上和 Android 一致:预热缓存 + 单 Engine + 协议收敛。"

### 11.6 "如果重新设计这个项目,你会改什么?"(最看人的问题)

准备 2~3 个真实反思,示例:
1. **失败层收敛**:dartz 停更,换成 Dart 3 sealed class + 模式匹配自实现 Result,减少依赖;
2. **json_serializable 引入**:依赖冲突解决后把手动 fromJson 交给代码生成,省样板;
3. **测试补位**:当时 bloc_test 有依赖冲突没铺开,我会先解决依赖再补测试,把"可测试性"从口头落到 CI;
4. 混合开发侧:Engine 预热从 Application 挪到按需预热(冷启动耗时敏感时),加启动埋点量化。
- 这题答"没想改的"是减分,答"推翻重来"也是减分,**有具体反思 + 有权衡**才是高级工程师的样子。

---

## 附:配套文档

| 文档 | 内容 |
|---|---|
| [Dart语言面试题大全.md](./Dart语言面试题大全.md) | Dart 语言全部考点(异步/闭包/Isolate/空安全等) |
| [Flutter面试题大全.md](./Flutter面试题大全.md) | Flutter 框架全部考点(三棵树/渲染/手势/动画等) |
| [面试指南-混合开发集成方案.md](./面试指南-混合开发集成方案.md) | 混合开发集成细节 |
| [面试高频问题与答案.md](./面试高频问题与答案.md) | 通用高频问题 |
| [项目经历代码依据.md](./项目经历代码依据.md) | 项目叙事的代码出处 |

**最后一条建议**:这三份文档里,本文档(简历专项)优先级最高——面试官的问题 80% 会落在你简历写过的词上。每个"简历原话"小节末尾的**项目话术**,建议对着你自己的代码 `flutter_ecom/lib/` 过一遍,确保每个引用的文件你都能现场打开讲。

祝面试顺利!
