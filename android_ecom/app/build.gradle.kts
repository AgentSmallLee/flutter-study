plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "com.example.androidecom"
    // Flutter 3.47 的 :flutter 库以 compileSdk 36 构建，
    // 宿主工程必须 >= 36，否则 AGP 的 AAR metadata 检查会失败
    compileSdk = 36

    defaultConfig {
        applicationId = "com.example.androidecom"
        minSdk = 24
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }
    buildFeatures {
        viewBinding = true
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("com.google.android.material:material:1.11.0")
    implementation("androidx.constraintlayout:constraintlayout:2.1.4")

    // ===== 方式一：源码依赖 Flutter Module（本地开发调试）=====
    //
    // 面试讲解点：
    // 这里的 :flutter 项目是由 settings.gradle.kts 中的
    // include_flutter.groovy 脚本自动生成的。
    //
    // 为什么不直接 implementation project(':flutter_ecom')？
    // 因为 Flutter Module 不是标准的 Android library，
    // 它需要 Flutter Gradle 插件来处理 Dart 代码编译、产物打包等。
    // include_flutter.groovy 会把 Flutter 模块包装成一个标准的
    // Android library 项目（名为 :flutter），然后原生工程像依赖
    // 普通 library 一样依赖它。
    //
    // 注意：这种方式需要本地安装 Flutter 环境，适合 Flutter 开发同学调试。
    implementation(project(":flutter"))

    // ===== 方式二：产物依赖 aar（多仓模式 / 团队协作，正式环境）=====
    //
    // 面试讲解点：
    // 多仓模式下，Flutter 团队负责打 aar 产物并发布到 maven 仓库，
    // 原生团队只需要依赖 aar，不需要搭 Flutter 环境。
    //
    // 示例：
    // implementation("com.example.flutter_ecom:flutter_release:1.0.0")
    //
    // 也可以依赖本地 aar 文件：
    // implementation(files("libs/flutter-release.aar"))
    //
    // ===== 两种方式对比 =====
    // ┌──────────┬──────────────┬──────────────┬──────────────┐
    // │          │  源码依赖     │  aar 产物依赖  │  适用场景     │
    // ├──────────┼──────────────┼──────────────┼──────────────┤
    // │ Flutter 环境│     需要     │    不需要     │              │
    // │ 编译速度  │     慢       │     快       │              │
    // │ 调试效率  │    高        │     低       │              │
    // │ 团队协作  │  耦合高       │    解耦       │              │
    // │ 适用阶段  │  开发调试     │   正式发版    │              │
    // └──────────┴──────────────┴──────────────┴──────────────┘
    //
    // 实际项目中通常是：Flutter 开发同学用源码依赖，
    // 原生团队和 CI/CD 用 aar 产物依赖。
}
