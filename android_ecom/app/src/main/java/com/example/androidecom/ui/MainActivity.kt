package com.example.androidecom.ui

import android.os.Bundle
import android.widget.Button
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.example.androidecom.R
import com.example.androidecom.bridge.FlutterBridgeManager
import io.flutter.embedding.android.FlutterActivity

/**
 * 原生主页面
 *
 * 面试讲解点：
 * 这是红松 App 原生的首页（演示用简化版），点击「心选」Tab 跳转到 Flutter 电商模块。
 * 实际项目中，红松 App 的主框架都是原生的，电商业务模块用 Flutter 开发，
 * 用户点击「心选」Tab 时跳转到 Flutter 页面。
 *
 * 跳转方式有几种：
 * 1. 直接用 FlutterActivity 打开（简单场景，本项目演示用）
 * 2. 用 FlutterFragment 嵌入原生 Activity（需要和原生 Tab 混排等复杂场景）
 * 3. 自定义 Activity 包装 FlutterFragment（最灵活，推荐生产环境用）
 *
 * ⚠️ 注意：
 * 这个类依赖 Flutter SDK（FlutterActivity），需要在 build.gradle 中添加 Flutter 依赖后才能编译。
 * 多仓模式下，依赖 Flutter aar 后即可正常编译。
 */
class MainActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        // 预加载 Flutter 引擎，提升后续打开 Flutter 页面的速度
        // 面试讲解点：
        // 实际项目中可以放到 Application.onCreate，或者首页渲染完成后再加载
        // 这里放在 onCreate 只是演示，真实项目要权衡对启动速度的影响
        FlutterBridgeManager.preloadEngine(this)

        // 打开 Flutter 电商首页
        findViewById<Button>(R.id.btnOpenEcom).setOnClickListener {
            // 使用缓存的引擎打开 Flutter 页面，秒开
            // 面试讲解点：
            // withCachedEngine 用预加载的引擎，打开速度快
            // withNewEngine 每次创建新引擎，打开慢但隔离性好
            startActivity(
                FlutterActivity
                    .withCachedEngine(FlutterBridgeManager.getEngineId())
                    .build(this)
            )
            Toast.makeText(this, "正在打开 Flutter 电商模块...", Toast.LENGTH_SHORT).show()
        }

        // 带参数打开 Flutter 商品详情页
        findViewById<Button>(R.id.btnOpenEcomWithParams).setOnClickListener {
            // 面试讲解点：原生跳转 Flutter 时如何传参？
            // 方式一：通过 initialRoute 传递路由 + 参数（推荐，简单直接）
            // 方式二：通过 MethodChannel 在跳转后主动调用 Flutter 方法传参
            // 方式三：通过 Intent extra 传递，Flutter 侧通过 Channel 读取
            //
            // 注意：带 initialRoute 就不能用 cached engine 了，
            // 因为缓存的引擎已经执行了默认路由，不能改初始路由。
            // 实际项目中一般用方式二：打开默认路由后，通过 Channel 传参跳转具体页面
            startActivity(
                FlutterActivity
                    .withNewEngine()
                    .initialRoute("/product/1001")
                    .build(this)
            )
            Toast.makeText(this, "打开 Flutter 商品详情：ID=1001", Toast.LENGTH_SHORT).show()
        }

        // 架构说明文字
        findViewById<TextView>(R.id.tvArchitecture).text = """
            架构说明（面试讲解）：

            • 多仓模式：Android / iOS / Flutter 各独立仓库
            • Flutter 以 Module 形式嵌入，产物为 aar / framework
            • 原生通过 MethodChannel 为 Flutter 提供能力
            • FlutterEngine 预加载，秒开 Flutter 页面
            • 混合栈路由由原生统一管理
            • 登录态由原生维护，Flutter 通过 Channel 获取
        """.trimIndent()
    }
}
