# 混合开发面试知识点

本项目涉及的 Flutter 混合开发核心面试题及答案要点。

---

## 1. Flutter 混合开发有哪几种集成方式？各有什么优缺点？

### 三种集成方式

| 方式 | 说明 | 优点 | 缺点 | 适用场景 |
|------|------|------|------|---------|
| **纯 Flutter App** | 整个 App 都是 Flutter 写的 | 简单、性能好、一套代码双端 | 已有原生 App 无法直接用 | 新项目、创业团队 |
| **Flutter Module 嵌入** | 原生 App 中嵌入 Flutter 模块 | 渐进式接入、不影响原有业务 | 混合栈复杂、需要维护 Channel | 已有原生 App、部分业务用 Flutter |
| **FlutterView 嵌入** | 原生页面中嵌入一个 Flutter 视图 | 最灵活、可局部嵌入 | 性能开销大、生命周期管理复杂 | 原生页面里嵌入 Flutter 组件 |

### 本项目方案
Flutter Module 方式，电商业务用 Flutter 开发，嵌入红松原生 App。

---

## 2. 多仓 vs 单仓，怎么选？

### 多仓（多仓库分离）
- **优点**：团队解耦、版本独立、原生不需要 Flutter 环境
- **缺点**：联调麻烦、版本管理复杂、基建成本高
- **适用**：大团队、业务线多、原生和 Flutter 团队独立

### 单仓（统一管理）
- **优点**：联调方便、版本一致、调试简单
- **缺点**：仓库越来越大、代码耦合、团队权限不好管
- **适用**：小团队、快速迭代、大家既写原生又写 Flutter

### 本项目方案
多仓模式，红松 Android / iOS / Flutter 各一个仓库，Flutter 打 aar 产物供原生依赖。

---

## 3. FlutterEngine 是什么？为什么要预热？

### FlutterEngine
Flutter 引擎，负责执行 Dart 代码、渲染 UI、处理事件等。每个 FlutterEngine 对应一个 Dart Isolate。

### 为什么要预热（预加载）？
- **首次创建耗时**：FlutterEngine 初始化需要加载引擎、初始化 Dart VM、执行入口函数，首次创建可能需要几百毫秒到 1 秒
- **预热后秒开**：提前创建并缓存引擎，打开 Flutter 页面时直接用缓存的引擎，几乎零延迟
- **内存权衡**：预热会占用一定内存（约 30-50MB），但换来的用户体验提升很值

### 引擎缓存方案
用 `FlutterEngineCache` 缓存引擎，通过 engineId 存取。
本项目在 `FlutterBridgeManager.preloadEngine()` 中实现。

---

## 4. 共享引擎 vs 多引擎，怎么选？

| | 共享引擎（单引擎） | 多引擎 |
|---|---|---|
| **内存** | 占用少 | 每个引擎 30-50MB，多开几个内存飙升 |
| **状态共享** | 天然共享，全局状态直接用 | 隔离，需要 Channel 通信同步状态 |
| **路由管理** | Flutter 内自己管理路由 | 每个引擎独立路由栈 |
| **适用场景** | 大部分业务场景 | 独立浮窗、独立隔离的业务模块 |

### 本项目方案
共享引擎模式，电商模块共用一个 FlutterEngine，通过 Flutter 内部路由管理页面。

---

## 5. MethodChannel / BasicMessageChannel / EventChannel 区别？

| Channel | 特点 | 适用场景 |
|---------|------|---------|
| **MethodChannel** | 异步方法调用，类似 RPC | 调用原生方法、获取原生能力（登录、支付、相机） |
| **BasicMessageChannel** | 基础消息传递，双向 | 传递字符串/半结构化数据、持续通信 |
| **EventChannel** | 事件流，原生主动发事件 | 原生推送消息给 Flutter（如推送、传感器数据） |

### 本项目方案
主要用 MethodChannel，因为大部分是 Flutter 调用原生能力。
如果需要原生主动通知 Flutter（如登录状态变化），可以用 EventChannel 或 MethodChannel 的反向调用。

---

## 6. 混合开发中登录态怎么处理？

### 常见方案

1. **原生维护登录态，Flutter 通过 Channel 获取**（推荐）
   - 登录页用原生，登录成功后 Token 存在原生
   - Flutter 每次启动时通过 MethodChannel 从原生获取 Token
   - 优点：登录态统一，不会出现两端不一致
   - 本项目方案

2. **Flutter 自己维护登录态**
   - 登录页用 Flutter，Token 存在 Flutter 侧
   - 原生如果需要登录态，通过 Channel 从 Flutter 取
   - 适合 Flutter 是主体的 App

3. **两端各自维护，登录时同步**
   - 登录成功后两边都存一份
   - 退出登录时两边都清
   - 需要处理好同步，容易出问题

### Token 自动刷新策略
- Dio 拦截器检测 401
- 调用原生刷新 Token 接口
- 刷新成功后重试原请求
- 刷新失败则通知原生跳登录页

---

## 7. 混合栈路由怎么管理？

### 核心问题
原生页面和 Flutter 页面交错跳转时，页面栈怎么管理？返回手势怎么处理？

### 常见方案

1. **FlutterActivity / FlutterViewController 单页面嵌入**（简单）
   - 整个 Flutter 模块作为一个原生页面
   - Flutter 内部路由自己管理
   - 返回时直接 finish 整个 Activity
   - 适合 Flutter 业务模块整体嵌入

2. **FlutterFragment 嵌入**（灵活）
   - 原生 Activity 中嵌入 FlutterFragment
   - 可以和原生 View 混搭
   - 生命周期需要自己管理

3. **混合栈框架**（复杂场景）
   - 闲鱼 FlutterBoost、美团 Flint 等
   - 原生和 Flutter 页面交错跳转，统一管理页面栈
   - 实现复杂，适合深度混合开发的 App

### 本项目方案
方案 1，电商模块作为整体嵌入原生 App，内部用 go_router 管理 Flutter 路由。
返回原生页面通过 MethodChannel 调用 `navigateBack` 通知原生 finish。

---

## 8. 混合开发的性能优化有哪些？

### 引擎层面
- **引擎预热**：提前初始化 FlutterEngine，秒开页面
- **引擎复用**：尽量用共享引擎，减少内存占用和创建耗时
- **减少引擎数量**：避免频繁创建销毁引擎

### 页面加载
- **首屏占位图**：Flutter 页面加载前显示原生占位图，避免白屏
- **预渲染**：进入页面前先触发帧调度
- **减少初始化工作**：非首屏数据懒加载

### 内存优化
- **及时释放不需要的资源**：图片缓存、大对象
- **列表优化**：ListView.builder 懒加载、const 构造函数
- **RepaintBoundary**：独立渲染层，减少重绘

### 通信优化
- **减少 Channel 调用次数**：批量获取数据，避免频繁调用
- **异步处理**：Channel 调用是异步的，不要阻塞 UI
- **数据序列化**：用基本类型和 Map，避免复杂对象序列化

---

## 9. 混合开发有哪些坑？

1. **内存占用大** — Flutter 引擎本身有内存开销，低端机需注意
2. **页面跳转体验** — 原生跳 Flutter 可能有短暂黑屏/白屏
3. **状态同步复杂** — 原生和 Flutter 状态不同步，比如购物车数量
4. **调试困难** — 混合问题需要两端排查
5. **发布流程复杂** — Flutter 发版和原生发版节奏不同步
6. **包体积增大** — Flutter 引擎 aar 会增加包体积（ armeabi-v7a 约 5MB）
7. **第三方插件兼容** — 有些 Flutter 插件在混合开发模式下有问题
8. **生命周期管理** — Flutter 页面的生命周期和原生页面不一样

---

## 10. Flutter 绘制原理（三棵树）

面试高频题，虽然是纯 Flutter 知识，但混合开发面试也经常问。

### 三棵树
1. **Widget 树** — 配置信息，不可变，每次 build 都可能重建
2. **Element 树** — Widget 的实例化，管理生命周期，比较稳定
3. **RenderObject 树** — 实际负责布局、绘制的渲染对象

### 为什么是三棵树不是两棵？
- Widget 轻量，重建成本低，声明式 UI 的基础
- Element 中间层，做 diff，复用 RenderObject，避免频繁创建销毁
- RenderObject 负责实际布局绘制，重，不轻易重建

### setState 流程
调用 setState → 标记 Element 为 dirty → 下一帧重建 Widget → diff → 更新 RenderObject → 重新布局绘制

---

## 面试答题技巧

1. **先说结论，再说细节** — 别铺垫半天面试官没听到重点
2. **结合项目说** — 理论 + 我们项目里是怎么做的，这样最有说服力
3. **承认边界** — 不知道就说"这块我了解得不是很深，我知道的是……"，别瞎编
4. **引导到你熟悉的领域** — 比如被问 iOS 的问题，可以说"iOS 侧我了解得不多，我主要做 Android 侧，Android 这边是这样的……"
