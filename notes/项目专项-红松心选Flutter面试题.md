# 项目专项面试题:红松心选 Flutter 客户端

> 依据 `简历.md` 项目经历「红松心选 Flutter 客户端」的技术栈与 6 条核心职责逐条出题。项目面试题与知识点面试题不同:**面试官会用"怎么做的、为什么这么做、遇到什么问题、效果怎么量化"四连来验证经历的真实性**。本文档每节包含:考察意图、问题与参考答案、追问链、以及基于 flutter_ecom 真实代码的话术(面试时可对照源码讲)。
>
> 姊妹篇:[Dart语言面试题大全.md](./Dart语言面试题大全.md) / [Flutter面试题大全.md](./Flutter面试题大全.md)(原理储备)/ [简历技能点-Flutter面试题.md](./简历技能点-Flutter面试题.md)(技能关键词专项)。本文档聚焦**项目叙事与实现细节**,纯原理不再重复展开。

---

## 目录

1. [项目总览与"技术负责人"角色](#一项目总览与技术负责人角色)
2. [技术选型与架构设计(职责一)](#二技术选型与架构设计)
3. [混合开发端到端落地(职责二,最重头)](#三混合开发端到端落地)
4. [核心基础设施建设(职责三)](#四核心基础设施建设)
5. [核心业务模块开发(职责四,逐模块实现细节)](#五核心业务模块开发)
6. [性能优化与质量保障(职责五)](#六性能优化与质量保障)
7. [本地存储方案设计(职责六)](#七本地存储方案设计)
8. [数字类问题盘点(<100ms / 55fps / 百万级)](#八数字类问题盘点)
9. [质疑型与压力面试问题](#九质疑型与压力面试问题)
10. [项目叙事的完整开场白(背熟)](#十项目叙事的完整开场白)

---

## 一、项目总览与"技术负责人"角色

> 项目描述:Flutter Module 多仓模式嵌入 Android/iOS 原生 App,以 aar/framework 产物集成,涵盖首页、分类、搜索、商品详情、购物车、订单、登录完整电商链路,服务百万级用户。Flutter 团队 3 人,担任 Flutter 技术负责人。

### 1.1 "用两分钟介绍一下这个项目"(100% 开场题,必须备稿)

建议结构(SPA):
- **背景**:红松主 App 是中老年兴趣学习平台,心选是其中的电商业务线。业务诉求是"电商迭代快、双端一致",而原生团队要同时维护小课/文旅/电商多条业务线,电商被挤成二等公民;
- **方案**:我主导选择 Flutter Module 混合开发——以模块嵌入主 App,复用宿主登录态、支付、推送;原生壳 + Flutter 业务页,双端一套代码;
- **我的角色**:3 人 Flutter 团队的技术负责人,从 0 到 1:技术选型与架构(Clean Architecture + flutter_bloc + get_it)、混合开发方案双端落地(Bridge 协议、Engine 预热秒开)、网络/路由/DI/错误治理四大基建、首页/商详/购物车/订单核心模块开发、性能专项(核心页面 55fps+);
- **结果**:Flutter 首页秒开(<100ms)、前后端通过 Mock 并行开发,百万级用户稳定运行。

### 1.2 "你是技术负责人,具体负责什么?3 个人怎么分工的?"

准备一个诚实且立体分工:
- **我**:架构与选型、混合开发双端方案(原生壳也是我,Android 出身写 Kotlin 无压力)、网络/路由/DI/错误处理基建、Bridge 协议制定、购物车与订单模块、性能专项、Code Review 与规范;
- **成员 A**:首页/分类/搜索模块(在我的首页模板上开发);
- **成员 B**:商详/登录/组件库沉淀;
- **协作机制**:每周需求评审对齐后端接口 → 我出接口文档与 Bloc 状态设计(轻量设计文档)→ 各自开发 → MR 我 review(检查分层是否越界、状态是否类型化、const/细粒度刷新)→ 打 aar/framework 给原生联调。
- 追问:**review 时你主要看什么?** 答:① presentation 不许 import data(分层纪律);② State 必须 Equatable 且类型化(不许 bool 大杂烩);③ 列表必须 builder + const;④ Bridge 调用必须走 NativeBridge 收口(不许散落 MethodChannel);⑤ dispose 完整性(订阅/Timer)。

### 1.3 "从 0 到 1,你们前两周做了什么?"(过程真实性题)

标准叙事:**先修路再跑车**——
1. 第 1 周:选型 spike(对比 demo:最小 bloc/get_it/go_router 工程跑通)、目录结构约定、代码规范文档(flutter_lints 定制)、Bridge 协议 v1(先定登录态 + 支付两个最难的);
2. 第 2 周:四大基建(DioClient + 拦截器、Failure 体系、AppRouter、service_locator)+ MockApiAdapter(此时后端接口还没出,全员 Mock 并行开发首页);
3. 第 3 周起:按模块并行开发,我同时支持原生侧壳(Engine 预热)。
- 这题答得好能直接证明"负责人"不是头衔。核心信息:**Mock 先行让前后端解耦,是 3 人小团队能并行交付的关键决策**。

### 1.4 "服务百万级用户"对这个模块意味着什么?(工程视角题)

- **质量门槛**:电商模块的崩溃影响宿主 App 整体稳定性 → 所有 Bridge 调用异常收口(PlatformException 不许穿透)、网络错误全部 Failure 类型化、绝不让模块把宿主搞崩;
- **兼容性**:中老年用户设备偏老旧(低端安卓占比高)→ 性能优化按低端机档位验收(这是"55fps"的背景,详见第八节);
- **灰度与回滚**:混合开发的优势场景——aar 产物随宿主 App 灰度,出问题可以按业务开关降级回原生入口;
- **降级能力**:Bridge 失败、引擎初始化失败的兜底路径(详见 3.9)。

---

## 二、技术选型与架构设计

> 职责一原文:"主导电商 Flutter 模块从 0 到 1 的技术选型与架构设计,采用 Clean Architecture 三层分层,确定 flutter_bloc + get_it 的技术路线,制定代码规范与目录结构约定,沉淀开发文档"

### 2.1 每个选型的"为什么"——一张决策表(必背)

面试官问"为什么选 X 不选 Y"时,**先说替代方案、再说取舍理由**,展示的是决策过程而非结论:

| 选型 | 对比过的方案 | 决策理由 |
|---|---|---|
| flutter_bloc | Provider / Riverpod / GetX | ① Event 驱动可审计(BlocObserver 统一日志/上报);② 强约束,3 人团队防"随手改状态";③ 纯 Dart 类离屏可测。Riverpod 更现代但当时(2024 中)生态与心智成本对我们不划算;GetX 全家桶耦合深,直接排除 |
| Equatable | freezed | 我们要的只是"值相等去重",Equatable 零代码生成、无构建链路;freeze 的 copyWith/union 更全,但当时 build_runner 与部分插件有版本冲突(真实经历),团队选择手写样板换构建稳定 |
| get_it | Riverpod 的容器 / injectable | 手写注册集中一处、启动链路清晰、无生成依赖;配合"只在两个边界 getIt"的纪律控制 Service Locator 缺点 |
| Dio | http / dart:io HttpClient | 拦截器链、CancelToken、Adapter 可替换(Mock 的地基)、超时细粒度配置——http 太裸 |
| go_router | Navigator 1.0 / auto_route | 官方维护、声明式支持 deep link/恢复(混合开发里原生可驱动 URL)、ShellRoute 原生解决底部导航外壳;auto_route 生成式我们想减构建依赖 |
| Hive + sp | sqflite / Isar | 详见第七节,按数据特性分层选型 |
| dartz | try/catch + 自定义 Result | Either 把失败放进签名,编译期强制处理(细节见简历技能点文档·五) |
| 混合开发 | 独立 Flutter App / RN 页面 | 见第九节压力题 9.1,这是必被问的 |

### 2.2 "如果现在重新选型,你会改什么?"(看视野的题)

准备 2~3 条(说明你跟进生态但不盲目追新):
- dartz 已停止维护 → 用 Dart 3 **sealed class + 模式匹配**自实现 Result/Union(几行代码,零依赖,还拿到穷尽性检查);
- Riverpod 3 稳定后值得再评估(编译期安全、AsyncValue 原生异步);
- 依赖冲突解决后,json_serializable/freezed 可以回归,减样板。
- 反面答案"全换新框架"会显得没有判断。

### 2.3 目录结构怎么定的?为什么按 feature 不按 layer 分?

```dart
lib/
├── core/        // 跨业务基建(di/network/router/error/bridge/widgets/extensions)
└── features/    // 按业务:home/cart/order/auth/... 每个内部分 data/domain/presentation
```

- **按 feature 分**:一人负责一个 feature 目录,MR 不打架;删除/迁移一个业务模块是物理隔离的;
- **feature 内按层分**:3 人协作时,层级纪律靠 review 保证;
- 规范落地手段:flutter_lints 开严格规则 + review 清单 + `core/` 里沉淀模板代码让新人"抄模板"。
- 追问:**feature 之间怎么依赖?** 只允许依赖 `core/`,feature 互相依赖要提升到 core(我们定过这条规,比如通用组件统一进 core/widgets)。

### 2.4 "沉淀开发文档"具体指什么?

- ① 选型决策记录(ADR 简版:背景/候选/理由);② 目录与命名约定;③ Bridge 协议文档(通道名/方法名/参数/错误码,给原生同学看的双端契约);④ 新模块模板(从 repository→usecase→bloc→page 的标准链路示例);⑤ 常见坑记录(如 pubspec 注释里存的 Flutter 3.47 插件兼容坑)。
- 面试金句:"**文档不是写给别人看的,是写给我们三个月后的自己的**——尤其 Bridge 协议,双端没有契约文档就是互相扯皮"。

---

## 三、混合开发端到端落地

> 职责二原文:"负责 Android 原生壳与 Flutter 业务两端的混合开发方案设计与实现,采用多仓 + Flutter Module 模式,以 aar 产物形式集成,原生侧与 Flutter 侧的 Bridge 协议均由本人主导设计与开发;实现 FlutterEngine 预加载与缓存策略,在闪屏页期间同步预热引擎,Flutter 电商首页秒开(<100ms);设计 NativeBridge 单例管理器与 FlutterBridgeManager,基于 MethodChannel 统一封装登录态共享、微信支付等原生能力"

**这是整份简历里最值钱的一段**(双端、协议、量化指标都有),面试官大概率花最多时间在这里。原理储备见 Flutter 面试题大全·第十五节,此处全是落地细节。

### 3.1 多仓 + Flutter Module 模式怎么组织的?(必考)

- **仓库结构**:主 App 仓(android_ecom 这类宿主)+ flutter_ecom module 仓,两个独立 Git 仓,CI 产物解耦;
- **集成链路**:
  - 开发期:宿主 `settings.gradle` 用 binding/includeBuild 引入 Flutter module 的构建(Flutter module 自带 `.android` Gradle 工程),宿主直接依赖,**改 Dart 代码宿主立即可见**;
  - 发布期:`flutter build aar --release`(iOS 侧 `flutter build ios-framework` 产出 framework),原生侧按 Maven/Pod 形式集成产物——**Flutter 团队与原生团队的编译链路解耦**,原生同学不需要本机装 Flutter 环境;
- **版本管理**:aar 产物带版本号,宿主依赖固定版本,Flutter 侧升级不影响原生构建(除非通道协议变化,需双端同步发版);
- 追问①:**为什么不用源码集成上線?** 产物集成隔离性好、原生构建快、职责边界清晰;源码集成只在联调期用;
- 追问②:**aar 里包含什么?** Flutter 的 jar(Embedder)+ libapp.so(AOT 产物)+ libflutter.so(Engine)+ assets,所以 aar 有多架构(arm64-v8a 等)分产物——顺势可以聊 `flutter build aar --release --target-platform android-arm,android-arm64` 和宿主 abiFilters。

### 3.2 FlutterEngine 预热与缓存——"<100ms 秒开"怎么实现的?(必考,数字被写上简历就会被问)

分三步讲:

1. **预热位置**:Application/闪屏页创建并缓存 Engine:

```kotlin
// Application 或 SplashActivity onCreate:
val engine = FlutterEngine(this)
engine.dartExecutor.executeEntrypoint(
    DartExecutor.DartEntrypoint(FlutterInitializer.findAppBundlePath(), "main"))
FlutterEngineCache.getInstance(this).put("ecom_engine", engine)
// 跳转:
startActivity(FlutterActivity.withCachedEngine("ecom_engine").build(this))
```

2. **为什么能 <100ms**:把三大冷启动成本全部前置——
   - Engine 创建(起 Dart VM、加载 libapp.so):**移到 App 启动/闪屏期间**,用户无感;
   - Dart 侧 main() 提前执行:我的 main 里做完 `configureDependencies()`(sp/Hive 初始化)+ Bloc 预加载(HomeBloc 单例注册即发首页请求)——**用户点进 Flutter 时,首页数据已经请求完或在途**;
   - 首帧数据不等待:页面渲染骨架屏 + BlocBuilder 响应已缓存状态,点击到可交互只差"Activity 启动 + Engine attach + 首帧 raster",这三个加起来 100ms 内。
3. **怎么测的**(必追问):闪屏页埋点结束 → Flutter 侧 `WidgetsBinding.addPostFrameCallback`(首帧渲染完成回调)打点,两个时间戳相减,线上灰度抽样统计 P50。P50 < 100ms,低端机 P90 在 200ms 左右——**主动交代 P50/P90 的区分,比只报一个数可信得多**。

追问链:
- **预热会不会拖慢 App 启动?** Application 里 create Engine 在异步/低优先级执行,主线程只做注册;真正执行 entrypoint 的重活 Dart VM 自己调度,闪屏页本来有展示时间,正好消化;
- **Engine 常驻内存多少?** 一个 Engine 全套约几十 MB(VM + ICU + shader cache),所以我们**全局单 Engine**,多入口用 `initialRoute` 区分而不是多 Engine;
- **Engine 预热后用户一直不进电商模块呢?** 内存换时机的 trade-off;闪屏期预热是"大概率会进"(启动入口直达)或运营位强导的场景;对低频入口可以延迟到"宿主空闲后再预热"(IdleHandler 思路)。

### 3.3 Bridge 协议你设计的,说说协议长什么样?(必考)

对着 `BridgeChannels`/`BridgeMethods` 讲设计原则:

```dart
// 通道命名:包名 + 功能名,防止与三方插件冲突
class BridgeChannels {
  static const nativeBridge = 'com.example.flutter_ecom/native_bridge';
  static const auth = 'com.example.flutter_ecom/auth';
  static const payment = 'com.example.flutter_ecom/payment';
  // camera / push ...
}
// 方法名常量化,双端共用同一份契约文档
class BridgeMethods {
  static const getAppInfo = 'getAppInfo';
  static const nativeLogin = 'nativeLogin';
  static const getToken = 'getToken';
  static const weChatPay = 'weChatPay';
  // ...
}
```

- **为什么业务 Bridge 不做成插件?** 插件适合通用能力(camera 这种三方都能用的);登录态/支付是和宿主强耦合的业务协议,单文件集中管理 + 一份协议文档,原生同学对齐改一处就行;
- **协议版本化**:新增方法不删老方法(向前兼容);参数只加字段不删字段;双端各自升级时,老版本调用不存在的方法会收到 `notImplemented`,NativeBridge 层捕获降级——**混合开发双端发版节奏不一致,兼容性是协议设计第一原则**;
- **参数与返回类型约束**:入参 Map<String, dynamic>/基本类型(StandardCodec 支持范围),返回同样;复杂对象在各自端内转模型(通道只传"数据的序列化形态");
- 追问:**怎么保证双端不写错方法名?** 常量收敛 + 协议文档 + 联调期的 Error 拦截日志(未实现方法直接在 Logging 拦截器级别打 error,一眼定位)。

### 3.4 NativeBridge(Flutter 侧)与 FlutterBridgeManager(Android 侧)的分工?

- **Flutter 侧 NativeBridge(单例)**:业务只见类型化方法(`getToken()`、`showToast()`),内部统一 try PlatformException → 日志 → 降级(返回 null/false,绝不让通道错误穿透 UI);**业务层被禁止直接 new MethodChannel**——通信细节、异常、日志一处收口;
- **Android 侧 FlutterBridgeManager**:实现 `MethodChannel.MethodCallHandler`,`onMethodCall` 按 method 分发,`result.success/error/notImplemented` 三态返回;还有反向调用(原生推 token 变化给 Flutter)时持有一个回传 channel;
- **单例的理由**:MethodChannel 本身轻量,但 Bridge 状态(如 pending 回调、监听注册表)需要唯一管理点;单例也方便原生侧持有引用做反向调用。
- 追问(高频):**MethodChannel 的线程模型?** 消息从 Dart(isolate 所在 UI 线程)序列化跨到 Engine,Handler 在**平台主线程**执行;原生回传同理。所以原生侧 Handler 里不能做重活(卡的是宿主主线程)——我在 FlutterBridgeManager 里做的是轻量分发,耗时操作(如相机)移到原生侧自己的后台再回传结果。

### 3.5 登录态共享的完整链路(简历点名,必考)

必须能白板画出来:

```
原生 SP/MMKV 存 token(单一数据源)
        │ ① 启动/进模块时 Dart 主动拉:getToken()/nativeLogin()
        ▼
NativeBridge → MethodChannel → FlutterBridgeManager 读原生存储 → 回传 token+用户信息
        ▼
AuthLocalDataSource 缓存 → AuthBloc(全局单例)emit AuthAuthenticated
        ▼
① 各页面从 AuthBloc 读登录态
② go_router refreshListenable 监听 AuthBloc.stream → 未登录访问受限页 redirect 到 /login
        ▲
        │ ② 原生侧登出/token 刷新:反向通道主动推
原生侧调用 Dart(setMethodCallHandler)
```

关键设计点(每条都是追问弹药):
- **单一数据源在原生**:token 的真身永远在宿主,Flutter 只做缓存镜像——避免双端状态打架;
- **推拉结合**:拉(进模块时初始化)+ 推(原生变化时同步),推用 Dart 端 `setMethodCallHandler` 监听原生反向调用(原生侧持有 FlutterEngine 的 dartExecutor channel);
- **401 双向处理**:Flutter 网络层 Error 拦截器收到 401 → UnauthorizedFailure → 通过 Bridge 通知原生刷新 token 或直接唤起原生登录页(电商场景简单粗暴:跳原生登录,回来再重试);
- 追问:**为什么 Flutter 不自己存 token?** 混合开发里宿主的支付/推送/分享全部读宿主侧登录态,如果 Flutter 另存一份必然漂移;单一数据源 + 镜像同步是唯一正确的形态。

### 3.6 微信支付的混合实现(简历点名,必考)

流程(对着讲,显示真做过):

```
Flutter 商品页 → 业务后端创建订单,返回支付参数(prepayId 等)
  → NativeBridge.weChatPay(payParams) → MethodChannel
  → 原生 FlutterBridgeManager 调起微信 SDK(WXAPI.sendPayReq)
  → 用户在微信完成支付 → 微信回调到宿主 App(WXPayEntryActivity.onResp)
  → 原生侧通过反向通道把支付结果推回 Flutter(或 Flutter 轮询)
  → Flutter 订单状态刷新(以后端订单状态为准)
```

三个必考深挖点:
1. **支付结果以服务端为准**:微信客户端回调可能丢(用户杀进程),所以支付结果**不能只信回调**——Flutter 侧拿到回调后先展示"支付确认中",然后查订单接口(服务端收微信异步通知才是真状态);没有回调也能在回到前台时轮询兜底;
2. **payParams 为什么要原生中转?** 签名在后端完成,但**调起微信 SDK 必须原生**(wxapi 注册、包名签名校验),Flutter 无法直接调——这正是 Bridge 存在的意义;
3. **失败/取消的分支处理**:errCode 区分用户取消(-2)与失败,取消不弹错误页、返回待支付状态;Bridge 超时(用户停在微信)不能阻塞 UI,Promise 不 resolve 的话用 mounted 检查 + 状态轮询。
- 加分:"我们踩过**回调后 Flutter 页面不在前台**的坑(用户直接在微信里杀宿主),所以订单页在 didChangeAppLifecycleState resumed 时主动查单,这就是靠生命周期兜底"。

### 3.7 aar 产物集成后,原生的混淆/包体积怎么处理?

- **混淆**:Dart AOT 不需要混淆,但插件里的 Java/Kotlin 代码走宿主 R8 → Bridge/插件相关的 keep 规则由 module 的 consumer proguard 文件带上(`flutter build aar` 会打包 consumer-rules),宿主无感;
- **包体积**:module 引入约 +4~6MB(engine + libapp.so);**abiFilters 收敛 arm64-only** 时减半;图片资源走网络+缓存不下发到包里;
- 追问:**libapp.so 是什么?** Dart AOT 编译后的机器码,按架构分产物。

### 3.8 iOS 侧的对称方案讲两句(会被问,你主导双端)

- `flutter build ios-framework` 产出 `.framework`/XCFramework,Pod 集成;
- Engine 预热:`FlutterEngine(runWithEntrypoint:)` 在 AppDelegate 启动时预热 + `FlutterEngineCache`;
- Bridge 协议同一套(Flutter 侧零改动),只是 Handler 用 Swift/OC 实现——**通道协议的双端无关性是 MethodChannel 的价值**,我在 Android 侧实现后 iOS 侧照协议抄实现即可。

### 3.9 混合开发的降级与容错(高级题,答好显架构成熟度)

- **Bridge 失败降级**:所有通道调用异常收口在 NativeBridge(PlatformException → log → 返回 null/false),UI 按"能力不可用"降级(如原生长图选择不可用就只给 URL 输入);
- **引擎初始化失败**:闪屏页预热带超时检查,超时 fallback 到原生 H5 容器(电商兜底方案)或提示重试;
- **模块开关**:后端下发功能开关,宿主可把电商入口整体切回原生/H5——**混合开发的可回滚性是它对比"改不动原生 App"的核心优势**,这句话面试官很认;
- **灰度**:aar 随宿主 App 灰度放量,监控模块内错误率与帧率。

---

## 四、核心基础设施建设

> 职责三原文:"基于 Dio 封装统一网络客户端,设计 Auth/Logging/Error 三层拦截器链,结合 dartz Either 与 6 种 Failure 类型实现函数式错误处理;基于 go_router 搭建声明式路由体系,实现 ShellRoute 嵌套导航与路由守卫;搭建 get_it 依赖注入体系,规范全局单例 Bloc 与页面级工厂 Bloc 的选型策略"

原理与代码细节在 [简历技能点-Flutter面试题.md](./简历技能点-Flutter面试题.md) 三、四、五、六节已详述(拦截器顺序、Either 论证、ShellRoute/refreshListenable、单例/工厂表),此处只列**项目负责人视角的增量问法**。

### 4.1 "6 种 Failure 类型"——具体哪 6 种?为什么这样分?(简历数字必被问)

对照 `failures.dart` 正好 6 种,背下来:

| 类型 | 触发场景 | UI 表现策略 |
|---|---|---|
| ServerFailure | HTTP 5xx | "服务器开小差" + 重试按钮 |
| NetworkFailure | 连接超时/DNS/断网 | 引导检查网络 |
| UnauthorizedFailure | 401 | 全局跳登录(联动 AuthBloc + 路由守卫) |
| BusinessFailure(带 code) | HTTP 200 但 code != 成功 | 直接展示后端 message |
| CacheFailure | Hive/本地读写失败 | 静默降级 + 日志上报 |
| UnknownFailure | 兜底 | 通用错误页 |

- 为什么枚举出类型:**每类错误的"用户该看到什么"和"系统该做什么"不同**——401 是全局行为(跳登录),业务错误是页面行为,缓存失败甚至不该打扰用户;类型化 = 策略表,处理代码从 if 地狱变成 `fold`/switch 穷尽匹配。
- 追问:**Failure 的 == 怎么写的?** 按类型 + message 值比较(手写 operator==/hashCode),这样 BusinessFailure 进 State 后 Equatable 去重能正确工作——串起三层知识,是好答案。

### 4.2 "编译期强制调用方处理失败分支"——真的编译期强制吗?(可能被抬杠)

诚实答:Either 的"强制"是**类型层面的**:返回值是 Either<Failure,T>,调用方拿到的不是裸 T,必须 fold/map(或显式 `.getOrElse`)才能拿到值——**你无法假装失败分支不存在**;try/catch 可以整个忘写。严格说是"编译器逼你拆包",不是"逼你写正确处理",但错误被忽略的可能性从"忘了 catch"降到"故意 fold 里不管"。
- 加分:dartz 停更后,官方形态是 Dart 3 sealed class + switch 穷尽性检查,那就连"故意不管"都过不了编译——我已经在新设计里这样规划(见 2.2)。

### 4.3 三层拦截器链的"负责人级"讲法

不只讲顺序(请求正序、响应逆序),补三条工程决策:
1. **Error 拦截器是唯一异常转译点**:DioException/HTTP 状态码/业务 code 统一在此映射成 6 种 Failure——**仓储层往下只见 Either,不见 DioException**,异常治理收口在 data 层边界;
2. **Logging 拦截器生产环境降级**:kDebugMode 全量,body 超长截断;release 只记元数据(url/statusCode/耗时),不打用户数据(合规);
3. **Auth 拦截器只加头不判断 401**(判断归 Error),单一职责。

### 4.4 go_router 体系的负责人级要点

- URL 即状态:/home /cart /product/:id 全部可寻址,混合开发里**原生可以拿到 location 直接驱动 Flutter 路由**(deep link/推送跳转落地在 Bridge);
- ShellRoute 外壳(MainShell 底部导航)与全屏页用 `parentNavigatorKey: _rootNavigatorKey` 分离,登录页不带 tab 栏;
- 路由守卫 + `refreshListenable(AuthBloc.stream)`:登录态变化自动重评估 redirect——"**路由守卫不靠手动拦截,靠状态驱动重评估**"是声明式路由的精髓表述。

---

## 五、核心业务模块开发

> 职责四原文:"主导首页(轮播图+分类横滑+推荐商品+下拉刷新/加载更多)、商品详情(SliverAppBar 沉浸式滑动+图片画廊+规格选择底部弹层)、购物车(多选/全选/数量调整/合计计算+Hive 本地持久化)、订单(列表/详情/取消/确认收货+自定义物流时间线组件)等核心模块开发"

**每个模块面试官都能下钻三层:布局怎么实现 → 状态怎么组织 → 坑在哪**。以下逐模块准备。

### 5.1 首页:结构拆解

**结构**:EasyRefresh 包 ListView → 轮播图(carousel_slider + smooth_page_indicator 指示器)→ 分类横滑(Horizontal ListView)→ 推荐商品瀑布流网格。

高频问答:

1. **下拉刷新/加载更多怎么实现的?** EasyRefresh 的 `onRefresh` 重置页码发请求 emit 新 Loaded;`onLoad` 页码+1 追加,`hasMore=false` 时禁用加载更多并展示"没有更多了"。**分页字段在 State 里**(页码/hasMore),List 追加用 `[...old, ...new]` 生成新列表(不可变)——Equatable 值比较识别内容变化。
2. **首页一次要三个接口(banners/categories/products),怎么发?** HomeBloc 收到 InitialEvent 后并行 `Future.wait` 三个 UseCase,**各自 fold**——任何一个失败不拖垮其它(banner 挂了商品照常显示),State 是部分成功型:`HomeLoaded(banners, categories, products)` 中 banner 可为空集。追问"一个失败全部失败?"就答"设计上选择部分成功,电商首页可用性优先"。
3. **轮播图的坑?** 自动播放 Timer 在 dispose 时必须销毁(EasyRefresh/carousel 内部管理,但自写轮播的 Timer 是泄漏高发区);PageView 缓存 `allowImplicitScrolling` 影响预渲染;轮播图片用 `memCacheWidth` 限制解码尺寸。
4. **首页为什么是单例 HomeBloc?** 切 tab 不重新请求,回显缓存数据(见简历技能点·3.4)。

### 5.2 商品详情:SliverAppBar 沉浸式(简历点名,必考)

对着 `product_detail_page.dart` 讲:

```dart
CustomScrollView(slivers: [
  SliverAppBar(
    pinned: true,                    // 滚出后固定一个压缩态 AppBar
    expandedHeight: 375,             // 展开态高度 = 图片首屏
    flexibleSpace: FlexibleSpaceBar(
      background: ProductImageGallery(...),  // 图片画廊做背景
      title: ...                      // 标题随滚动渐显
    ),
  ),
  SliverToBoxAdapter(商品信息区),
  ...
])
```

高频问答:

1. **"滚动时标题渐显"怎么实现的?** FlexibleSpaceBar 标题默认带视差与淡入效果,其原理是 `FlexibleSpaceBar` 内部用 `MediaQuery`/scroll offset 驱动 title 的 opacity 与 scale;自定制时可以在 `SliverAppBar` 的 flexibleSpace 外监听 `ScrollController` 计算 offset/treshold 手动控制透明度(讲出"默认行为 + 手动接管"两层)。
2. **沉浸式布局为什么用 CustomScrollView 而不是 NestedScrollView?** 商详是"头部大图 + 长内容"的单轴滚动,sliver 一根滚动轴性能最好;NestedScrollView 适合头部与 body 联动的场景。
3. **图片画廊怎么做?** `PageView` + `smooth_page_indicator`,页码"1/5"指示;大图预览复用 PageView(可加 PhotoView 放大);图片仍走 AppNetworkImage(缓存统一)。
4. **规格选择底部弹层?** `showModalBottomSheet(isScrollControlled: true)` 包自封装的 `ProductSpecSheet`(StatefulWidget 维护"每个规格组当前选中值"的 Map)——**为什么 isScrollControlled?** 内容超高时需要撑满约束自定义高度,默认 sheet 高度受限。
5. **SKU 联动(如果被问深)?** 数据层 sku 列表按规格组合展开,选中态变化时计算"当前组合对应的 skuId 与价格";部分组合无货要禁用态——这是电商最深的坑,准备好"我们用 specs/values 扁平组合 + Map 查找"的实现概述即可。

### 5.3 购物车:状态设计 + Hive 持久化(简历点名)

1. **多选/全选/数量/合计的状态机怎么组织?** 单一 CartBloc,State 类型化(CartLoading/CartLoaded(items, selectedIds, ...));合计 **不在 State 里存字段,而是派生属性**(`double get totalPrice` 由 items+selected 计算)——**单一数据源原则:能推导的不存储**,否则数量与合计可能不一致。合计变化自动驱动 UI(BlocBuilder 包合计 Text,State 变化即重建)。
2. **全选的状态计算?** selectedIds.length == items.length 派生,同样不存;点击全选是发 ToggleSelectAll 事件**改数据**,不是改 UI 标志——"**事件改数据,状态是数据的投影**"是状态机驱动的核心表述。
3. **数量增减的边界?** 底/上限约束(1~库存),防抖/节流后端同步(本地先改 UI 即时反馈,服务端异步对账——电商标准"乐观更新"策略,失败回滚并 Toast)。
4. **Hive 持久化细节**(接第七节):productId 为 key、增删改 O(1)、离线可用;登录后与服务端购物车**合并策略**(本地未支付项与服务端按 productId 合并,数量取大/叠加,以服务端为准)——合并策略是加分题,提前想好口径。
5. **角标同步**:底部导航角标 BlocSelector 只订阅 totalCount(简历技能点·9.4 的实证)。

### 5.4 订单:列表分页 + 状态流转 + 物流时间线

1. **订单列表**:分页同首页;**状态筛选**(全部/待付款/待收货...)通过 URL query `initialStatus` 传入(`state.uri.queryParameters['status']`)——筛选状态进 URL,深链/推送可直接定位"待付款列表",这是声明式路由的实用收益;
2. **取消订单/确认收货 = 状态流转**: Bloc 事件 CancelOrder → UseCase → 成功后**重新拉取详情**(或本地 emit 新状态),UI 按订单状态渲染可执行操作按钮集合——本质是小状态机,非法操作(对已取消订单再点取消)在 UI 层就不渲染按钮,**非法状态不可表示**;
3. **自定义物流时间线组件**(简历点名):

```dart
// LogisticsTimeline(updates: [...]) 纯组合实现:
Column(children: [
  for (final (i, update) in updates.indexed)
    Row([
      圆点+连线(自绘 Container,当前节点高亮色),
      Column([时间格式化, 物流描述]),
    ])
])
```

- 被问"为什么不用 CustomPainter?":节点数少(<10),**组合 Widget(容器+边线)比自绘 Canvas 更简单、可访问性(Semantics)免费、还能复用主题色**;数据量大或需要曲线/视差才上 CustomPainter——**"能在 Widget 层解决就不下到 Canvas 层"** 的取舍意识;
- 时间线数据细节:按时间倒序(最新在上)、首节点高亮、时间格式化用 intl(国际化串联);
4. **订单页退出后取消未完成请求**:CancelToken 在 dispose 触发——和"setState after dispose 防御"串起来讲。

### 5.5 "把控核心业务逻辑的正确性与性能表现"——你怎么把控的?

- **正确性**:核心链路(下单/支付/购物车合计)状态机先画状态图再写代码;Money 用字符串/分计算避免 double 精度坑(合计计算用分为单位整数再格式化);边界 case 清单(review 对照);
- **性能**:模块级 lint(列表 builder/const/细粒度刷新)+ profile 模式抽查关键页面;
- 加分细节:**金额计算用整数分**是电商必踩坑,主动说出来很值钱。

---

## 六、性能优化与质量保障

> 职责五原文:"通过 cached_network_image 三级缓存、列表项 const 构造、BlocSelector 细粒度刷新、搜索输入防抖等手段优化列表滑动流畅度,核心页面帧率稳定在 55fps 以上;封装 AppNetworkImage、PrimaryButton、通用状态页等组件;设计 MockApiAdapter 实现接口 Mock,支持前后端并行开发"

手段的原理级答案见简历技能点·九,此处是**专项叙事 + 量化口径 + 组件化治理**。

### 6.1 "55fps 以上"怎么测出来的?(数字必被追问,口径要一致)

标准答案结构:
1. **测法**:`flutter run --profile`(强调 debug 不能测,JIT+断言失真),DevTools Performance 面板看帧时间轴;关键页面(首页/商详/购物车/订单)固定操作脚本(滑动列表、进商详、切规格弹层);
2. **设备档位**:中老年用户低端机占比高,按"低端基准机"(如 2GB 内存、中端 4 核)验收,不是旗舰机测着玩;
3. **指标口径**:滑动时 UI 线程 + Raster 线程均 <16ms 为满帧;**55fps 指的是滑动场景平均值**(偶发 jank 到 50 但不连续),持续低于 55 才算问题;优化前商详滚动在低端机约 45fps,优化后 55+;
4. **上线监控**:关键页面通过 `SchedulerBinding.addTimingsCallback` 埋点帧耗时,灰度上报聚合(有这个闭环才算"稳定在"三个字)。
- 答题要点:**主动交代"profile 模式、低端基准机、滑动场景均值、有埋点闭环"四要素**,把"55fps"从吹牛变成工程结论。

### 6.2 优化专项的"前后对比"叙事(每手段:问题→定位→手段→效果)

| 问题现象 | 定位 | 手段 | 效果 |
|---|---|---|---|
| 首页商品图滑动掉帧,Raster 泳道超时 | 图片原图解码上传大纹理 | cached_network_image + `memCacheWidth` 按显示尺寸解码 | 光栅耗时显著降 |
| 列表整行随购物车重建闪烁 | BlocBuilder 包整页 | item 组件拆分 + BlocSelector(角标只订 totalCount) | 重建范围缩到单 Widget |
| 输入"a"再输"ab"结果错乱回显 | 请求竞态后返回覆盖 | 防抖(debounceTime)+ switchMap 取消旧流 | 结果永远与最新输入一致 |
| 切 tab 首页重新加载白屏 | 页面级 Bloc 每次新建 | 单例 HomeBloc 首次加载缓存 | 秒显缓存数据 |

- 这张表是**"发现问题→量化验证"的方法论展示**,比罗列技巧高级。

### 6.3 组件封装治理:为什么要统一 AppNetworkImage/PrimaryButton/状态页?

- **AppNetworkImage**(包 cached_network_image):全 App 图片的统一入口——**唯一**设置占位图、错误图、圆角、memCacheWidth 默认值的地方;后来图片规范调整(如默认解码宽度策略)只改一个文件,这是"封装"的真实收益;
- **PrimaryButton**:主题色、按压态、loading 态(防重复提交:异步期间禁用按钮)统一;
- **通用状态页**(empty_state/error_state/loading_indicator):Loading/空/错误三态标准化,错误页带重试回调——所有 Bloc 状态机映射到同一套状态页,**UI 一致性 + 开发提速**(新人接业务页不用重画错误页);
- 话术:"组件库的本质是把**设计规范编译成代码**,UI 团队出图和我们封装是同一个规范的两面"。

### 6.4 MockApiAdapter:设计细节(简历点名,技术含量高)

对着 `mock_api_adapter.dart` 讲:

```dart
class MockApiAdapter implements HttpClientAdapter {
  // fetch 拦截真实网络,按 path 匹配本地 JSON 直接构造 ResponseBody 返回
}
```

- **为什么在 Adapter 层 Mock 而不是拦截器层?** Dio 的 `HttpClientAdapter` 是"真正发 HTTP"的最后一站,替换它 = 整个网络栈(含拦截器、BaseResponse 解析)全部走真实代码路径——**Mock 到最底层,联调时零切换成本**(只把 useMock 常量改 false);
- **Mock 数据组织**:assets 下按路由存 JSON,path 正则匹配,支持延迟模拟 loading 与错误码模拟(测错误分支!);
- **前后端并行**:接口文档(字段契约)一出,前端先按文档 Mock 开发,后端完成联调切换——**3 人团队敢按双周迭代交付,Mock 先行是前提**;
- 追问:**为什么不用抓包工具/Postman Mock?** 那要求后端 mock 服务先行,且环境耦合;Adapter Mock 是代码库内的、版本化的(测试同学也能复现同一份数据)。

### 6.5 质量保障还有什么?(补全拼图)

- bloc_test 单测(当时因依赖冲突部分手写测试,新版本后回归标准 blocTest——呼应 2.2 的"改什么"答案);
- BlocObserver 上线监控(状态迁移/错误上报,9.6 的闭环一环);
- Code Review 清单(1.2);
- 灰度发布 + 功能开关降级(3.9)。

---

## 七、本地存储方案设计

> 职责六原文:"购物车结构化数据使用 Hive NoSQL 存储,自定义 TypeAdapter 实现类型安全的对象序列化,以 productId 为 key 保证单条记录唯一性;用户 Token、搜索历史等轻量 KV 数据使用 SharedPreferences;两种方案各取所长"

机制对比与选型表见简历技能点·八,此处聚焦简历点名两点的深挖。

### 7.1 "以 productId 为 key"——为什么?(简历点名,小细节大作用)

对着 `cart_local_datasource.dart`:

```dart
Future<void> put(CartItemHiveModel item) async {
  await _box.put(item.productId, item);  // 同一商品只有一条记录
}
CartItemHiveModel? getByProductId(int productId) => _box.get(productId);
```

- **唯一性约束在存储层兜底**:同一商品再加购不会产生两条记录,key 冲突自动覆盖——比业务层去重更可靠(忘了判重也不会脏数据);
- **O(1) 单条更新**:数量变化只 `put` 单 key;若用自增 key + list 遍历查找更新是 O(n),且要处理"查到/查不到"两分支;
- **删除 O(1)**:`_box.delete(productId)`;
- 对比 Java:"这就是我原生里用 SP 时 `key = "cart_" + productId` 的做法,教训在 NoSQL 里同样适用——**key 设计就是数据模型设计**"。
- 追问:**Hive 的 put 是全量写还是增量?** append-only 二进制日志追加写,无需全文件重写(对比 SP),这也是选 Hive 做购物车高频写的原因之一。

### 7.2 自定义 TypeAdapter 的代价与决策(必追问)

- **为什么手写而不是 hive_generator?** 真实原因:当时 hive_generator/bloc_test 与 Flutter 版本存在依赖冲突,我们锁了插件版本并手写 Adapter(以及手动 fromJson),构建链路换依赖健康——这个决策在 pubspec 注释里就有记录,照实讲最有说服力;
- **手写 Adapter 的纪律**:write 与 read 字段顺序必须严格一致;**加字段只能 append 到尾部**,不能插中间(老数据反序列化错位);知道这些坑说明真写过;
- **TypeAdapter 类型安全的意义**:Box<CartItemHiveModel> 泛型约束,取出即是模型而不是 Map,序列化边界不出现在业务层(dataSource 内部完成 HiveModel ↔ Entity 转换,呼应四层对象:Entity/Model/HiveModel 各守一个序列化边界)。

### 7.3 sp 管哪些?为什么不都用 Hive?

- token(由登录态链路写)、搜索历史(List 序列化字符串或 JSON)、用户偏好开关——**扁平 KV、无嵌套对象、读写频率低**;
- 一律上 Hive 会引入 schema/Adapter 维护成本;sp 的"启动全量入内存 + 同步读"对这几个字段恰好是最省心的形态;
- 一句话总结选型原则:**"结构化(对象/单条可变/频繁写)用 Hive,扁平 KV(轻量/低频)用 sp"**。

---

## 八、数字类问题盘点

简历里所有数字都会被问"怎么来的",统一准备口径:

| 数字 | 口径话术 |
|---|---|
| **首页秒开 <100ms** | 闪屏埋点 → Flutter addPostFrameCallback 首帧打点,P50 灰度抽样;<100ms 的前提是 Engine 预热 + Dart main 提前执行 + 首页数据预热;低端机 P90 约 200ms |
| **55fps+** | profile 模式 + 低端基准机 + 滑动场景均值;优化前 ~45fps;线上 addTimingsCallback 帧埋点闭环 |
| **百万级用户** | 宿主 App 累计用户,电商模块随宿主触达;工程含义:低端机占比、灰度回滚、不能拖垮宿主稳定性 |
| **3 人团队 / 完整电商链路** | 见 1.2 分工 + 1.3 先基建后业务的排期;Mock 先行 + 组件库/模板让平行开发成立 |
| **6 种 Failure** | 见 4.1 表格 |
| **0 到 1** | 先修路(选型/基建/Mock)再跑车(模块并行),两周基建后进入业务迭代 |

**口径一致性提醒**:这些数字在面试不同问题里会被反复验证(比如问了秒开再问帧率,再问团队分工),**每次的口径必须一致**,前后矛盾是致命伤。不确定的数字宁可说"P50 大约,记不太精确"。

---

## 九、质疑型与压力面试问题

### 9.1 "公司已有 RN 团队(你 Android 简历里写着和 RN 协同过),为什么电商不用 RN?"(最尖锐,必须提前想透)

三层答法:
1. **场景匹配**:RN 的价值在"热更新 + 原生控件";但我们此前和 RN 协同时**踩过通信层白屏、数据丢失的兼容性问题**(我 Android 简历里就写着排查这些),电商这种强交互、复杂列表、高一致性要求的业务,Flutter 自绘引擎的渲染性能和稳定性更可控;
2. **性能**:Flutter AOT 无 JS 运行时、无桥接序列化层,复杂列表与动画帧率稳定;
3. **团队**:我 Android 出身 + 团队具备快速上手 Dart/Flutter 的能力,RN 需要维护 JS 双端差异,Flutter 一套代码双端一致。
- 收尾金句:"**选型不是比谁的技术更先进,是比谁的风险更可控**——RN 的白屏问题我们替业务踩过一次,电商场景赌不起"。

### 9.2 "为什么不做一个独立的 Flutter 电商 App?"(反向质疑)

- 用户资产在宿主:登录态、支付、推送、分享全部依赖宿主,独立 App 意味着重新登录/冷启动全链路成本;
- 业务定位:电商是主 App 的业务线(用户在学习场景里顺手买),不是独立产品;
- 工程角度:混合模式下电商可以**独立发版节奏**(aar 产物),又不失去宿主渠道;
- 反问意识:"如果未来电商独立运营,模块化的好处是——Flutter module 本身就能以极低成本切换成独立 App,架构上没锁死。"

### 9.3 "3 个人做完整个电商链路,是不是吹的?"(真实性验证)

- 不卑不亢:"链路完整但**深度有节制**——首页/商详/购物车/订单是标准电商形态,组件库和基建是我先建好的,模块开发是'在模板上长业务';真正花时间的反而是混合开发的 Bridge 协议与预热方案。另外 Mock 先行让前后端不互相等,3 个人的并行度才高。"
- 现场可快速画出的证据:目录结构、Bridge 协议、拦截器顺序、购物车状态机——**每个追问都能落到具体代码**,比语言自辩有力。

### 9.4 "你在项目里最大的失误/最想重做的决策?"

准备一个真实、有反思深度但非致命的案例:
- 示例:dartz 依赖(停更)的选型当时只看了 API 合适,没评估维护活跃度,后来想升级 sealed class 方案时多了一层迁移成本——**教训是引入小众依赖要评估维护者活跃度与替代成本**;
- 或:早期拦截器把 401 处理放在 Auth 拦截器里,后来发现响应阶段的逆序语义让它与 Error 拦截器职责纠缠,重构为"Auth 只加头、Error 统一转译"——**教训是设计时先明确责任链每节点的单一职责**。

### 9.5 "百万级用户的项目,出了线上事故怎么办?举一个。"

准备一个(可以基于真实经验构造的)案例模板:**现象**(灰度期间某版本购物车合计偶发为 0)→ **定位**(BlocObserver 上报 + 用户路径还原:未登录用户本地购物车合并逻辑)→ **修复**(合并策略补齐 + 埋点)→ **机制改进**(购物车合并 case 进 review 清单、灰度观察期延长)。展示的是**事故响应闭环**,不是背一个完美故事。

### 9.6 "混合开发如果 Flutter Engine 和宿主 App 内存打架怎么办?"

- 单 Engine 常驻(约几十 MB)+ 不用时 destroyEngine 可选;图片缓存上限配置;模块内页面退出不销毁单例 Bloc 但大对象懒加载;宿主侧有内存监控,模块帧率/内存随灰度观察——展示"混合开发的内存责任边界是**双方共管**,协议里要约定谁持有什么"。

### 9.7 离职原因/为什么找 Flutter 岗位(人事+技术双重考察)

- 技术侧口径:电商模块 0 到 1 完成、架构稳定进入维护期,我希望找 Flutter 全栈业务更深(独立 App/更大规模)的场域继续成长;
- 与你"Android 转 Flutter"的叙事线一致:**不是逃离原生,而是带着原生视角做跨端**——混合开发负责人这个角色恰恰需要两个世界都懂,这是你的稀缺性,不是短板。

---

## 十、项目叙事的完整开场白(背熟)

> "红松心选是红松 App(中老年兴趣学习平台,千万级用户)里的电商业务线。因为电商迭代快、双端一致要求高,而原生团队被小课/文旅多条线占满,我主导立项用 **Flutter Module 混合开发**:以 aar/framework 产物嵌入双端宿主,复用宿主登录态和支付,电商模块独立迭代。
>
> 我担任 3 人 Flutter 团队的技术负责人,做了三件事:一是 **0 到 1 的架构与选型**,Clean Architecture 三层 + flutter_bloc + get_it 这条技术路线,连同目录规范、拦截器链、Either + 6 种 Failure 的错误治理、go_router 声明式路由,这套基建让小团队具备了并行开发能力;二是 **混合开发双端落地**,Bridge 协议我设计的,NativeBridge/FlutterBridgeManager 双端收口,FlutterEngine 在闪屏期预热缓存,电商首页做到 P50 <100ms 秒开;三是 **核心业务与性能**,首页/商详/购物车/订单全链路我主导开发,性能专项后核心页面在低端基准机上稳定 55fps 以上,通过 MockApiAdapter 支撑前后端并行,百万级用户稳定运行。
>
> 这个项目里我最得意的两点:一是登录态共享的**推拉结合设计**——原生单一数据源、Flutter 镜像同步、401 双向联动、路由守卫状态驱动;二是全链路的**错误治理**——从通道异常到网络错误全部类型化收口,业务层看不到裸异常。"

两分钟讲完,面试官自然会把问题引向他感兴趣的段落——而每一段你都有本文档对应的深挖答案。

---

## 附:配套文档

| 文档 | 用途 |
|---|---|
| [Dart语言面试题大全.md](./Dart语言面试题大全.md) | Dart 语言原理(被下钻时的储备) |
| [Flutter面试题大全.md](./Flutter面试题大全.md) | Flutter 框架原理(三棵树/渲染/混合开发原理) |
| [简历技能点-Flutter面试题.md](./简历技能点-Flutter面试题.md) | 专业技能关键词专项(bloc/Dio/go_router/get_it 细节) |
| [项目经历代码依据.md](./项目经历代码依据.md) / [面试指南-混合开发集成方案.md](./面试指南-混合开发集成方案.md) | 项目叙事的代码与集成细节出处 |

**使用建议**:本文档与《简历技能点》配套——技能点文档管"原理答得对",本文档管"经历讲得真"。面试前重点过第三节(混合开发)、第八节(数字口径)、第十节(开场白);每个话术引用的源文件(`native_bridge.dart`、`dio_client.dart`、`product_detail_page.dart`、`cart_local_datasource.dart` 等)建议再打开过一遍,确保细节描述与代码零偏差。

祝面试顺利!
