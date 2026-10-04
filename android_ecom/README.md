# android_ecom

Android 电商 App 原生工程，集成 Flutter Module 实现混合开发。对应红松 App「心选」电商模块的 Android 端宿主工程。

## 项目简介

本项目是一个 Android 原生应用，以 **Flutter Module** 的形式集成了 Flutter 开发的电商业务模块。采用**多仓模式**架构，Android 原生工程与 Flutter 工程分别独立维护，通过 aar 产物或源码方式集成。

### 核心特性

- **Flutter 引擎预加载**：App 启动时预热 FlutterEngine，打开 Flutter 页面接近秒开
- **MethodChannel 通信桥接**：统一管理原生与 Flutter 的双向通信
- **两种集成方式**：支持源码依赖（开发调试）和 aar 产物依赖（多仓协作）
- **原生能力下沉**：登录、支付、相机等能力由原生提供，Flutter 通过 Channel 调用

## 项目结构

```
android_ecom/
├── app/
│   ├── src/main/
│   │   ├── java/com/example/androidecom/
│   │   │   ├── ui/
│   │   │   │   └── MainActivity.kt       # 原生首页，演示跳转 Flutter
│   │   │   └── bridge/
│   │   │       └── FlutterBridgeManager.kt # Flutter 桥接管理器（引擎/Channel）
│   │   ├── res/                           # 原生资源
│   │   └── AndroidManifest.xml
│   ├── build.gradle.kts                   # app 模块构建配置
│   └── proguard-rules.pro                 # 混淆规则（含 Flutter 相关）
├── build.gradle.kts                       # 根构建文件
├── settings.gradle.kts                    # 项目设置 + Flutter Module 引入
├── FLUTTER_INTEGRATION.md                 # Flutter 集成详细指南
└── README.md
```

## 技术栈

| 类别 | 技术 |
|------|------|
| 语言 | Kotlin |
| 构建工具 | Gradle + AGP 8.11.1 |
| 最低版本 | minSdk 24 (Android 7.0) |
| 目标版本 | targetSdk 34 (Android 14) |
| 编译版本 | compileSdk 36 |
| UI | ViewBinding + Material Design |
| 混合框架 | Flutter 3.x (Module 形式) |

## 快速开始

### 环境要求

- Android Studio Iguana 及以上
- JDK 17
- Flutter SDK（**源码依赖模式需要**，产物依赖模式不需要）

### 目录约定

本工程（`android_ecom`）与 Flutter Module 工程（`flutter_ecom`）为**兄弟目录**关系：

```
Flutter_Study/
├── android_ecom/      ← 本项目（Android 宿主）
└── flutter_ecom/      ← Flutter Module 工程（源码依赖时需要）
```

### 方式一：源码依赖（开发调试）

默认已配置好源码依赖，确保兄弟目录存在 `flutter_ecom` Flutter Module 工程即可。

```bash
# 1. 确保 Flutter Module 在兄弟目录
ls ../flutter_ecom

# 2. 直接在 Android Studio 中运行项目
# 或命令行构建
./gradlew assembleDebug
```

### 方式二：产物依赖（多仓模式）

适合原生团队独立开发，不需要本地 Flutter 环境：

1. 在 `settings.gradle.kts` 中移除 `include_flutter.groovy` 相关代码
2. 在 `app/build.gradle.kts` 中将 `implementation(project(":flutter"))` 替换为 aar 依赖：

```kotlin
implementation("com.example.flutter_ecom:flutter_release:1.0.0")
```

3. 添加 maven 仓库地址，然后正常构建即可。

详细集成说明见 [FLUTTER_INTEGRATION.md](./FLUTTER_INTEGRATION.md)。

## 核心架构

### Flutter 引擎管理

`FlutterBridgeManager` 单例统一管理 Flutter 引擎的生命周期：

- **预加载**：在 `MainActivity.onCreate` 中预热引擎（实际项目可放到 `Application.onCreate` 或首页渲染后）
- **引擎缓存**：通过 `FlutterEngineCache` 缓存，多个 Flutter 页面共享同一引擎
- **秒开体验**：使用缓存引擎打开 Flutter 页面，大幅减少白屏时间

### 通信机制

通过 **MethodChannel** 实现原生与 Flutter 的双向通信，Channel 名称为：
`com.example.flutter_ecom/native_bridge`

#### Flutter 调用原生（已实现）

| 方法 | 功能 |
|------|------|
| `getAppInfo` | 获取 App 信息（版本、渠道、平台） |
| `toast` | 原生 Toast 提示 |
| `navigateBack` | 返回上一页（原生关闭 FlutterActivity） |
| `nativeLogin` | 获取登录用户信息 |
| `getToken` | 获取登录 Token |
| `logout` | 退出登录 |
| `aliPay` | 支付宝支付 |
| `takePhoto` | 调用相机拍照 |

#### 原生调用 Flutter

通过 `FlutterBridgeManager.invokeFlutterMethod()` 主动调用 Flutter 方法，适用于：
- 登录状态变化通知
- 推送消息到达通知
- 主题/语言切换通知

### 页面跳转

- **缓存引擎跳转**：`FlutterActivity.withCachedEngine(engineId)` —— 秒开，无初始路由参数
- **新引擎跳转**：`FlutterActivity.withNewEngine().initialRoute(route)` —— 可指定初始路由，但启动慢

> 实际项目推荐方案：用缓存引擎打开默认路由后，通过 MethodChannel 传参跳转具体页面，兼顾速度与灵活性。

## 构建

```bash
# Debug 构建
./gradlew assembleDebug

# Release 构建
./gradlew assembleRelease

# 安装到设备
./gradlew installDebug
```

## 相关文档

- [Flutter Module 集成指南](./FLUTTER_INTEGRATION.md) — 详细的集成方式、打 aar、多环境配置、常见问题

## License

本项目用于 Flutter 混合开发学习与面试演示。
