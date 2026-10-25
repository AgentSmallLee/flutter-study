# Flutter executeDartEntrypoint 调用场景详解

> 问题：Flutter 混合开发，都需要提前调用 `dartExecutor.executeDartEntrypoint(DartEntrypoint.createDefault())` 吗？
>
> 答案：**不一定，取决于你用哪种方式创建 FlutterEngine。但在 Add-to-App 预热引擎的场景下，必须手动调用。**

---

## 一、结论先行：什么时候需要手动调？

| 场景 | 是否需要手动调 `executeDartEntrypoint` | 原因 |
|---|---|---|
| **Add-to-App 预热引擎**（我们项目的方式） | ✅ **必须手动调用** | 自己 `FlutterEngine(context)` 创建的引擎，默认不会执行 Dart 代码 |
| **纯 Flutter App**（`FlutterApplication`） | ❌ 不需要 | 引擎创建时框架自动调用了 |
| **`FlutterActivity.withNewEngine()`** | ❌ 不需要 | Activity 内部创建引擎后自动调用了 |
| **`FlutterActivity.withCachedEngine()`** | ❌ 不需要（但要提前调） | 用缓存的引擎，引擎必须提前执行好 entrypoint |
| **`FlutterFragment.withNewEngine()`** | ❌ 不需要 | 同上，内部自动调用 |

---

## 二、为什么自己 new 的引擎要手动调？

`FlutterEngine(context)` 只是创建了引擎的**空壳**：

- ✅ Dart VM 启动了
- ✅ 渲染管线初始化了
- ✅ Platform Channel 的通道建立了
- ❌ **但 Dart 代码一行都没执行**

引擎不知道你要执行哪个 Dart 文件、哪个入口函数，所以需要你显式告诉它：

```kotlin
engine.dartExecutor.executeDartEntrypoint(
    DartExecutor.DartEntrypoint.createDefault()  // 执行 lib/main.dart 的 main()
)
```

---

## 三、`createDefault()` 是什么？

`DartEntrypoint.createDefault()` 等价于：

```kotlin
DartExecutor.DartEntrypoint(
    FlutterInjector.instance().flutterLoader().findAppBundlePath(),
    "main"
)
```

**两个参数：**

1. **`findAppBundlePath()`**：Dart 产物（kernel_blob.bin / app.so）在 APK assets 里的路径
2. **`"main"`**：要执行的 Dart 入口函数名

> 💡 **多入口用法**：你也可以指定其他入口函数，实现"多业务线多入口"：
> ```kotlin
> // 执行 lib/main.dart 里的 otherMain() 函数
> DartExecutor.DartEntrypoint(findAppBundlePath(), "otherMain")
> ```

---

## 四、为什么 `withNewEngine()` 就不用手动调？

因为 `FlutterActivity` / `FlutterFragment` 内部帮你做了。

以 `FlutterActivity` 为例，它内部的 `FlutterActivityAndFragmentDelegate` 在 `onAttach()` 里的逻辑大致是：

```kotlin
// withNewEngine() 模式下，内部大致做了这些事
if (withNewEngine) {
    flutterEngine = FlutterEngine(context)
    // 👇 框架自动帮你调用了
    flutterEngine.dartExecutor.executeDartEntrypoint(
        DartEntrypoint.createDefault()
    )
}
// withCachedEngine() 模式下，直接从缓存取，假设你已经执行过了
else {
    flutterEngine = FlutterEngineCache.getInstance().get(engineId)
}
```

> 💡 **设计原因**：`withNewEngine()` 是给"即用即建"的简单场景用的，不需要你关心引擎细节。但预热引擎是"高级用法"，你完全掌控引擎的生命周期，所以入口函数的执行也交给你自己决定。

---

## 五、纯 Flutter App 为什么也不用手动调？

纯 Flutter App 默认用 `FlutterApplication`（或者你自己的 Application 继承了 `FlutterApplication`）。

它的启动流程是：

```
Application.onCreate
    │
    ▼
FlutterInjector.instance().flutterLoader().startInitialization(this)
    │
    ▼
FlutterJNI.nativeInit  ← 初始化 Flutter 引擎的 native 层
    │
    ▼
FlutterActivity 启动时创建引擎 → 自动执行 DartEntrypoint
```

本质上还是框架自动调用了，只是你感知不到。

---

## 六、如果不调会怎么样？

如果你创建了 `FlutterEngine` 但不调用 `executeDartEntrypoint`，然后直接 `withCachedEngine` 打开页面：

```kotlin
// ❌ 错误示范：只创建引擎，不执行 Dart 入口
val engine = FlutterEngine(context)
FlutterEngineCache.getInstance().put("my_engine", engine)

// 然后打开页面
startActivity(FlutterActivity.withCachedEngine("my_engine").build(context))
```

**结果**：页面会白屏/黑屏，因为 Dart 代码根本没跑，没有 Widget 树，没有第一帧。FlutterView 会显示一个空白的渲染表面。

---

## 七、一句话总结

> **自己 `new FlutterEngine()` 创建的引擎，必须手动调 `executeDartEntrypoint` 来执行 Dart 代码，引擎只是个空壳不会自动跑 Dart。`withNewEngine()` 和纯 Flutter App 不用手动调，是因为框架内部帮你调了。**

---

## 相关文件索引

| 文件 | 作用 |
|---|---|
| `android_ecom/app/src/main/java/com/example/androidecom/bridge/FlutterBridgeManager.kt` | `preloadEngine()` 中手动调用 `executeDartEntrypoint` |
| `android_ecom/app/src/main/java/com/example/androidecom/ui/SplashActivity.kt` | 闪屏页调用预热引擎 |
