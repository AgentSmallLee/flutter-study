pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    // 面试讲解点：
    // Flutter Gradle 插件会通过 allprojects 给各子项目添加引擎 Maven 仓库
    // （https://storage.googleapis.com/download.flutter.io），
    // 用来下载 io.flutter:flutter_embedding_debug 等引擎产物。
    //
    // 必须用 PREFER_PROJECT（默认值），让子项目自己声明的仓库生效：
    // - 用 FAIL_ON_PROJECT_REPOS 会报 "Repository was added by a build script"；
    // - 用 PREFER_SETTINGS 会忽略子项目声明的仓库（包括 Flutter 引擎仓库），
    //   导致 "Could not find io.flutter:flutter_embedding_debug" 报错。
    repositoriesMode.set(RepositoriesMode.PREFER_PROJECT)
    repositories {
        google()
        mavenCentral()
        // ===== 多仓模式：Flutter aar 产物仓库 =====
        // 面试讲解点：
        // 正式环境下 Flutter 团队打 aar 产物发布到公司 maven 仓库，
        // 原生团队通过版本号依赖，不需要本地 Flutter 环境。
        // maven { url = uri("https://maven.company.com/repository/flutter-modules/") }
    }
}

rootProject.name = "android_ecom"
include(":app")

// ============================================================
//  ===== 源码依赖 Flutter Module（本地开发调试用）=====
// ============================================================
//
// 面试讲解点：
// 下面这行是 Flutter 官方提供的 include_flutter.groovy 脚本，它的作用是：
// 1. 把 Flutter 模块的 Android 代码注册为名为 :flutter 的 Gradle 子项目
// 2. 自动把所有 Flutter 插件的 Android 代码也注册为子项目
// 3. 配置 Flutter Gradle 插件和编译环境
//
// 适用场景：Flutter 开发同学本地调试，改完代码立即生效
// 缺点：需要本地 Flutter 环境、编译速度慢
//
// 多仓模式下（正式环境），这段可以替换为 maven 依赖 aar 产物。
apply(from = "../flutter_ecom/.android/include_flutter.groovy")
