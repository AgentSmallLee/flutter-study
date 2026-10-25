# Flutter 闪屏页跳转首页流程详解

> 项目：红松心选（android_ecom 原生壳 + Flutter 电商业务）
>
> 核心问题：从 `SplashActivity` 是如何跳转到 Flutter 首页并显示出来的？

---

## 项目架构：Add-to-App 混合开发模式

在讲跳转流程之前，先搞清楚项目的整体架构。我们的项目是 **原生壳 + Flutter 业务** 的混合开发模式（Flutter Add-to-App）。

### 项目结构

```
Flutter_Study/
├── android_ecom/          # 原生 Android 工程（壳工程）
│   ├── app/               # 主 module，包含 SplashActivity、FlutterBridgeManager 等
│   ├── build.gradle.kts
│   └── settings.gradle.kts
└── flutter_ecom/          # Flutter Module（电商业务模块）
    ├── lib/               # Dart 业务代码
    ├── pubspec.yaml
    └── .android/          # Flutter 自动生成的 Android 宿主代码
```

### 集成方式：源码依赖（本地开发调试）

当前项目采用 **Flutter 官方推荐的源码依赖方式**，通过 `include_flutter.groovy` 脚本集成。

#### 第一步：settings.gradle.kts 引入 Flutter 模块

`android_ecom/settings.gradle.kts` 第 48 行：

```kotlin
apply(from = "../flutter_ecom/.android/include_flutter.groovy")
```

> 💡 这行脚本的作用：
> 1. 把 Flutter 模块的 Android 代码注册为名为 `:flutter` 的 Gradle 子项目
> 2. 自动把所有 Flutter 插件（packages）的 Android 代码也注册为子项目
> 3. 配置 Flutter Gradle 插件和编译环境（Dart 编译、产物打包等）
>
> 为什么不直接 `include(":flutter_ecom")`？
> 因为 Flutter Module 不是标准的 Android library，它需要 Flutter Gradle 插件来处理 Dart 代码编译、资源打包等。`include_flutter.groovy` 会把 Flutter 模块包装成一个标准的 Android library 项目（名为 `:flutter`）。

#### 第二步：app/build.gradle.kts 依赖 flutter 项目

`android_ecom/app/build.gradle.kts` 第 61 行：

```kotlin
implementation(project(":flutter"))
```

这样原生工程就可以使用 Flutter 的所有 API 了，包括 `FlutterEngine`、`FlutterActivity`、`MethodChannel` 等。

### 另一种集成方式：aar 产物依赖（多仓模式/正式环境）

注释里也提到了 aar 产物依赖的方式：

```kotlin
// 多仓模式下，Flutter 团队打 aar 发布到 maven 仓库，原生团队依赖版本号
implementation("com.example.flutter_ecom:flutter_release:1.0.0")
```

#### 两种方式对比

| | 源码依赖 | aar 产物依赖 |
|---|---|---|
| Flutter 环境 | 需要本地安装 | 不需要 |
| 编译速度 | 慢（每次都要编译 Dart） | 快（直接用现成产物） |
| 调试效率 | 高（改完 Dart 立即生效） | 低（需重新打 aar） |
| 团队协作 | 耦合高（同仓） | 解耦（多仓） |
| 适用场景 | 开发调试 | 正式发版 / 原生团队 |

> 💡 **面试点**：实际项目中通常是两种方式并存 —— Flutter 开发同学用源码依赖调试，原生团队和 CI/CD 用 aar 产物依赖发版。

---

## 整体流程图

```
用户点击图标 → 系统绘制 windowBackground → SplashActivity.onCreate
       │                    │                          │
       │                    │                    预热 FlutterEngine
       │                    │                    （执行 Dart main）
       │                    │                          │
       │                    │                    延迟 1.5s 后跳转
       │                    │                          │
       │                    │                    FlutterActivity
       │                    │                （withCachedEngine）
       │                    │                          │
       ▼                    ▼                          ▼
  显示品牌色背景         闪屏页显示              Flutter 页面秒开
```

---

## 详细步骤

### 第一步：App 冷启动，系统绘制闪屏背景

**入口 Activity：** `SplashActivity`（在 `AndroidManifest.xml` 中声明为启动页）

```xml
<activity
    android:name=".ui.SplashActivity"
    android:exported="true"
    android:theme="@style/Theme.Splash"
    android:screenOrientation="portrait">
    <intent-filter>
        <action android:name="android.intent.action.MAIN" />
        <category android:name="android.intent.category.LAUNCHER" />
    </intent-filter>
</activity>
```

**关键机制：windowBackground**

主题 `Theme.Splash` 中设置了 `android:windowBackground`（`themes.xml`）：

```xml
<style name="Theme.Splash" parent="Theme.MaterialComponents.DayNight.NoActionBar">
    <item name="android:windowBackground">@drawable/splash_background</item>
    <item name="android:statusBarColor">@color/splash_background</item>
</style>
```

`splash_background.xml` 是一个 `layer-list`，包含背景色和居中 Logo。

> 💡 **面试点**：`windowBackground` 是系统在启动 Activity 时直接绘制的，比 `setContentView` 早很多，用户点击图标瞬间就能看到画面，从而避免冷启动白屏/黑屏。

---

### 第二步：SplashActivity.onCreate —— 预热 Flutter 引擎

`SplashActivity.onCreate()` 中**不调用 `setContentView`**，完全靠 `windowBackground` 展示画面，性能最优。

核心操作：

```kotlin
FlutterBridgeManager.preloadEngine(this)
```

`preloadEngine` 做了三件事（`FlutterBridgeManager.kt`）：

| 步骤 | 代码 | 作用 |
|---|---|---|
| 1 | `FlutterEngine(appContext)` | 创建 Flutter 引擎实例 |
| 2 | `dartExecutor.executeDartEntrypoint(DartEntrypoint.createDefault())` | 执行 Dart 的 `main()` 函数，Dart 代码开始运行 |
| 3 | `FlutterEngineCache.getInstance().put(ENGINE_ID, this)` | 将引擎存入缓存，key 为 `"ecom_engine"` |

> 💡 **预热时机选择**：
> - Application.onCreate：太早，拖慢 App 启动速度 ❌
> - **SplashActivity**：刚好，用户已经看到闪屏，等几百毫秒感知不到 ✅
> - 首页渲染完成后：太晚，用户点入口可能还没预热完 ❌

---

### 第三步：延迟跳转，保证最短展示时间

```kotlin
private const val SPLASH_MIN_DURATION = 1500L  // 最短 1.5 秒

val elapsed = System.currentTimeMillis() - startTime
val remaining = if (elapsed < SPLASH_MIN_DURATION) {
    SPLASH_MIN_DURATION - elapsed
} else { 0L }

handler.postDelayed({ navigateToEcomHome() }, remaining)
```

保证闪屏页至少显示 1.5 秒，避免初始化太快导致一闪而过，影响品牌展示效果。

---

### 第四步：跳转到 FlutterActivity（核心跳转逻辑）

```kotlin
private fun navigateToEcomHome() {
    val intent = FlutterActivity
        .withCachedEngine(FlutterBridgeManager.getEngineId())  // "ecom_engine"
        .build(this)
    startActivity(intent)
    finish()                                    // 关闭闪屏页
    overridePendingTransition(0, 0)             // 取消切换动画，无缝过渡
}
```

**三个关键点：**

| 操作 | 作用 |
|---|---|
| `withCachedEngine(id)` | **不创建新引擎**，直接从 `FlutterEngineCache` 取预热好的引擎，实现秒开 |
| `finish()` | 关闭 SplashActivity，用户返回不会回到闪屏页 |
| `overridePendingTransition(0, 0)` | 取消页面切换动画，实现"闪屏 → Flutter 首页"的无缝过渡，用户感觉像同一个页面 |

---

### 第五步：FlutterActivity 显示 Flutter 页面

`AndroidManifest.xml` 中注册的 `FlutterActivity`：

```xml
<activity
    android:name="io.flutter.embedding.android.FlutterActivity"
    android:configChanges="orientation|keyboardHidden|keyboard|screenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
    android:hardwareAccelerated="true"
    android:theme="@style/Theme.Flutter"
    android:windowSoftInputMode="adjustResize" />
```

**显示流程：**

1. `FlutterActivity` 通过 `withCachedEngine` 拿到缓存的引擎后直接 attach
2. 引擎里 Dart 代码已经在运行（预热时就执行了 `main()`），所以页面**直接渲染第一帧**
3. Flutter 侧 `main()` → `runApp()` → 电商首页 Widget 树构建 → 渲染到屏幕

**主题适配：** `Theme.Flutter` 设置了透明状态栏（`themes.xml`），让 Flutter 自己控制状态栏颜色，和纯 Flutter App 体验一致。

---

## 一句话总结

**闪屏页靠 `windowBackground` 秒显，期间预热 Flutter 引擎（执行 Dart main），1.5 秒后用 `withCachedEngine` 打开 `FlutterActivity`，直接复用预热好的引擎实现秒开，关闭闪屏页并取消切换动画，完成无缝过渡。**

---

## 相关文件索引

| 文件 | 作用 |
|---|---|
| `android_ecom/app/src/main/java/com/example/androidecom/ui/SplashActivity.kt` | 闪屏页 Activity，负责预热引擎和跳转 |
| `android_ecom/app/src/main/java/com/example/androidecom/bridge/FlutterBridgeManager.kt` | Flutter 引擎管理和 MethodChannel 注册 |
| `android_ecom/app/src/main/AndroidManifest.xml` | Activity 注册和启动入口声明 |
| `android_ecom/app/src/main/res/values/themes.xml` | Theme.Splash 和 Theme.Flutter 主题 |
| `android_ecom/app/src/main/res/drawable/splash_background.xml` | 闪屏页背景（layer-list） |
