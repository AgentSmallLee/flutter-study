# Flutter Module 集成指南

Android Android 原生工程如何引入 Flutter Module 的完整说明。

---

## 一、两种集成方式

### 方式 A：源码依赖（开发调试用）

**适用场景**：Flutter 开发同学本地调试、需要频繁修改 Flutter 代码

**优点**：
- 改完 Flutter 代码直接运行，立即可见
- 可以双向调试（原生 + Flutter 一起 debug）
- 不需要额外的发版流程

**缺点**：
- 需要本地安装 Flutter 环境
- 编译速度慢（每次都要编译 Dart 代码）
- 原生团队成员也需要搭 Flutter 环境

**配置方法**（已配置）：

```kotlin
// settings.gradle.kts
setBinding(new Binding([gradle: gradle]))
evaluate(new File(
    settingsDir.parentFile,
    'flutter_ecom/.android/include_flutter.groovy'
))

// app/build.gradle.kts
implementation(project(":flutter"))
```

---

### 方式 B：产物依赖（多仓模式 / 团队协作用）

**适用场景**：多仓模式、原生团队独立开发、CI 构建

**优点**：
- 原生团队不需要 Flutter 环境
- 编译速度快（直接用 aar 产物）
- 版本管理清晰，和原生依赖第三方库一样

**缺点**：
- Flutter 改动需要发版，原生需要升级版本
- 联调麻烦，改一个 Bug 要走发版流程
- 需要 maven 仓库管理产物

**配置方法**：

```kotlin
// settings.gradle.kts 中移除 include_flutter.groovy 相关代码
// app/build.gradle.kts 中改为：

// 从 maven 仓库依赖（多仓正式方式）
implementation("com.example.flutter_ecom:flutter_release:1.0.0")

// 或者依赖本地 aar 文件（临时调试）
implementation(files("libs/flutter-release.aar"))
```

---

## 二、Flutter Module 打 aar 产物

### 打 aar 命令

```bash
cd flutter_ecom

# 打 release 包
flutter build aar --no-debug --no-profile

# 只打指定架构（减小体积）
flutter build aar --no-debug --no-profile --target-platform android-arm64
```

### 产物输出位置

```
flutter_ecom/build/host/outputs/repo/
└── com/
    └── example/
        └── flutter_ecom/
            ├── flutter_release/
            │   ├── 1.0/
            │   │   ├── flutter_release-1.0.aar
            │   │   └── flutter_release-1.0.pom
            │   └── maven-metadata.xml
            └── flutter_release_2.17.0/   ← 插件 aar
                ...
```

### 发布到 maven 仓库

实际项目中，Flutter 团队会把 aar 发布到公司 maven 仓库，原生团队通过版本号依赖：

```kotlin
repositories {
    maven { url 'https://maven.company.com/repository/flutter-modules/' }
}

dependencies {
    implementation("com.example.flutter_ecom:flutter_release:1.2.3")
}
```

---

## 三、版本号管理

### Flutter 侧
`pubspec.yaml` 中的 `version: 1.0.0+1`
- `1.0.0` 是 versionName
- `1` 是 versionCode

### 原生侧
依赖 aar 时指定版本号：
```kotlin
implementation("com.example.flutter_ecom:flutter_release:1.0.0")
```

### 发版流程
1. Flutter 团队完成开发，打 aar 包
2. 发布到 maven 仓库，版本号 +1
3. 通知原生团队有新版本
4. 原生团队升级依赖版本号，测试验证
5. 发版上线

---

## 四、多环境配置

实际项目中通常有 dev / staging / release 多环境：

```kotlin
// 开发环境用源码依赖，方便调试
debugImplementation(project(":flutter"))

// 正式环境用 aar 依赖，稳定可靠
releaseImplementation("com.example.flutter_ecom:flutter_release:1.0.0")
```

或者通过构建变种（flavor）区分：

```kotlin
// 开发变种用源码
devImplementation(project(":flutter"))

// 生产变种用 aar
prodImplementation("com.example.flutter_ecom:flutter_release:1.0.0")
```

---

## 五、常见问题

### 1. 报 "Repository was added by a build script" 错误

原因：`repositoriesMode` 设置了 `FAIL_ON_PROJECT_REPOS`，但 Flutter 插件会自己加仓库。

解决：改成 `PREFER_SETTINGS` 或 `PREFER_PROJECT`

```kotlin
repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
```

### 2. 报 "flutter.sdk not set in local.properties"

原因：`.android/local.properties` 中没有 flutter.sdk 路径

解决：在 Flutter Module 目录下执行 `flutter pub get`，会自动生成

### 3. 混淆后 Flutter 页面白屏

原因：混淆把 Flutter 相关的类删掉了

解决：在 `proguard-rules.pro` 中添加 Flutter 混淆规则（本项目已配置）

### 4. 多个 Flutter 插件 aar 怎么处理

`flutter build aar` 会把所有插件的 aar 一起生成在 repo 目录下，
并且主 aar 的 pom 文件里会声明对插件 aar 的依赖，
所以原生只需要依赖主 aar，插件 aar 会自动传递依赖。
