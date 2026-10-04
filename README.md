# Flutter 混合开发电商项目

演示 **多仓模式 + Flutter Module** 的混合开发架构，用于简历和面试准备。

## 项目结构

```
Flutter_Study/
├── flutter_ecom/           # Flutter 业务模块（独立仓库）
│   ├── lib/
│   │   ├── core/           # 核心基础能力
│   │   │   ├── bridge/     # MethodChannel 原生 Bridge 封装 ⭐
│   │   │   ├── di/         # 依赖注入（get_it）
│   │   │   ├── network/    # 网络层（Dio + 拦截器）
│   │   │   ├── router/     # 路由（go_router）
│   │   │   └── widgets/    # 通用组件
│   │   ├── features/       # 业务模块
│   │   │   ├── auth/       # 登录
│   │   │   ├── home/       # 首页
│   │   │   ├── cart/       # 购物车
│   │   │   ├── order/      # 订单
│   │   │   └── ...
│   │   └── main.dart
│   ├── .android/           # Flutter 自动生成的 Android 宿主（调试用）
│   ├── .ios/               # Flutter 自动生成的 iOS 宿主（调试用）
│   └── pubspec.yaml
│
├── android_ecom/           # Android 原生电商 App（独立仓库）⭐
│   ├── app/
│   │   └── src/main/...
│   │       ├── bridge/     # FlutterBridgeManager（MethodChannel + 引擎管理）
│   │       └── ui/         # 原生页面
│   └── build.gradle.kts
│
└── 简历.md                  # 个人简历
```

## 架构模式

### 多仓 + Flutter Module 模式

```
┌─────────────────────┐     ┌─────────────────────┐     ┌─────────────────────┐
│  Android 原生仓      │     │  Flutter 业务仓      │     │  iOS 原生仓         │
│  android_ecom       │◀───▶│  flutter_ecom        │◀───▶│ （示例中省略）       │
│                     │     │                     │     │                     │
│ - 主框架 / 原生页面  │     │ - 电商业务模块       │     │ - 主框架 / 原生页面  │
│ - Flutter 容器       │     │ - Clean Architecture│     │ - Flutter 容器       │
│ - Bridge 原生实现    │     │ - Bridge 接口定义    │     │ - Bridge 原生实现    │
└─────────────────────┘     └─────────────────────┘     └─────────────────────┘
       ▲                            ▲                            ▲
       │                            │                            │
  Android 团队负责            你负责 + 双端联调              iOS 团队负责
```

## 核心亮点（面试重点）

### 1. Flutter 侧架构（Clean Architecture）
- **三层分层**：data / domain / presentation，职责清晰
- **状态管理**：flutter_bloc + Equatable，全局单例 + 页面级工厂混合模式
- **依赖注入**：get_it 统一管理所有依赖
- **网络层**：Dio + 自定义拦截器（Auth / Error / Logging）
- **路由**：go_router 声明式路由 + 路由守卫
- **本地存储**：Hive（购物车）+ SharedPreferences（轻量 KV）

### 2. 混合开发能力（重点加分项 ⭐）
- **Flutter Module 嵌入原生**：以 aar / framework 形式被原生依赖
- **FlutterEngine 预加载**：引擎缓存，秒开 Flutter 页面
- **MethodChannel 统一封装**：NativeBridge 管理器，集中管理所有原生能力调用
- **登录态共享**：原生维护登录态，Flutter 通过 Channel 获取 Token
- **原生能力封装**：相机 / 支付 / 推送 / 登录 等原生能力供 Flutter 调用
- **混合栈路由**：原生统一管理页面栈，Flutter 页面嵌入原生容器

### 3. 业务模块
- 首页（轮播图、分类横滑、推荐商品、下拉刷新、加载更多）
- 商品分类
- 搜索（防抖、历史记录、热门关键词）
- 商品详情（图片画廊、规格选择、服务保障、加入购物车）
- 购物车（本地持久化、数量调整、多选、全选、合计计算）
- 订单（列表、详情、取消、确认收货、物流时间线）
- 登录 / 个人中心

## 面试讲解思路

### 被问"你们 Flutter 和原生怎么协作的"

> "我们用的是**多仓 + Flutter Module** 的方式。Flutter 业务是一个独立的仓库，
> 以 module 形式分别嵌入 Android 和 iOS 的宿主 App，通过 aar / framework 产物集成。
>
> 我个人主要负责两块：
> 第一块是 **Flutter 侧的业务开发**，就是红松心选电商的完整业务，
> 用的是 Clean Architecture + flutter_bloc 的架构。
> 第二块是 **Android 侧的混合开发方案**，包括 FlutterEngine 的管理和预加载、
> 混合栈的路由跳转封装、还有原生 Bridge 层的设计——
> 就是把相机、支付、推送、登录这些原生能力封装成统一的 MethodChannel 接口
> 供 Flutter 调用，同时处理了混合页面的生命周期和内存管理问题。
>
> iOS 侧的接入是 iOS 团队负责的，我主要和他们对齐 Bridge 接口的协议定义。"

### 被问"为什么选多仓而不是单仓"

> "主要是基于团队和业务的考虑：
> 1. **团队解耦**：原生团队和 Flutter 团队是两个独立团队，各有各的代码仓库和发版节奏
> 2. **产物集成**：原生只依赖 aar 产物，不需要搭 Flutter 环境就能编译运行
> 3. **版本独立**：Flutter 模块可以独立发版，原生按需升级
>
> 当然单仓也有单仓的好处，比如联调方便。具体选哪种还是看团队规模和协作模式。
> 我们团队规模比较大，多仓更合适一些。"

## 快速运行

### 单独运行 Flutter 模块（调试用）

```bash
cd flutter_ecom
flutter pub get
flutter run
```

### Android 宿主集成 Flutter（混合开发模式）

实际项目中通过 maven 依赖 aar 产物。本地调试可以用源码依赖方式：

```kotlin
// settings.gradle.kts 中添加
setBinding(new Binding([gradle: this]))
evaluate(new File(
    settingsDir.parentFile,
    'flutter_ecom/.android/include_flutter.groovy'
))

// build.gradle 中依赖
implementation project(':flutter')
```

## 面试复习资料

| 文档 | 内容 | 建议阅读时间 |
|------|------|-------------|
| [面试指南-混合开发集成方案.md](面试指南-混合开发集成方案.md) | Flutter Module 两种集成方式 + 面试标准答案 + 常见追问 | 10 分钟 |
| [flutter_ecom/INTERVIEW_GUIDE.md](flutter_ecom/INTERVIEW_GUIDE.md) | 混合开发 10 道高频面试题 + 答案要点（引擎/Channel/混合栈/性能等） | 15 分钟 |
| [android_ecom/FLUTTER_INTEGRATION.md](android_ecom/FLUTTER_INTEGRATION.md) | 集成详细操作指南（打 aar、版本管理、多环境、常见问题） | 查阅用 |

---

## 技术栈

| 分类 | 技术 |
|------|------|
| 语言 | Dart / Kotlin |
| 状态管理 | flutter_bloc + Equatable |
| 架构 | Clean Architecture |
| 依赖注入 | get_it |
| 网络 | Dio + 拦截器 |
| 路由 | go_router |
| 本地存储 | Hive / SharedPreferences |
| 混合开发 | Flutter Module + MethodChannel + FlutterEngine |
| UI 组件 | easy_refresh / cached_network_image / carousel_slider |
