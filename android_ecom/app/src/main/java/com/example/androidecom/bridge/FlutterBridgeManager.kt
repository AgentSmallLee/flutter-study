package com.example.androidecom.bridge

import android.content.Context
import android.widget.Toast
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

/**
 * Flutter Bridge 管理器（单例）
 *
 * 面试讲解点：
 * 1. 统一管理 FlutterEngine 的创建和缓存，实现引擎预热
 * 2. 统一注册所有 MethodChannel，集中处理原生与 Flutter 的通信
 * 3. 业务层通过这个管理器和 Flutter 交互，不直接接触 FlutterEngine
 *
 * ⚠️ 注意：
 * 这个类依赖 Flutter SDK，需要在 build.gradle 中添加 Flutter 依赖后才能编译：
 * - 源码依赖方式：implementation(project(":flutter"))
 * - 产物依赖方式：implementation("com.example.flutter_ecom:flutter_release:1.0.0")
 *
 * 为什么要缓存 FlutterEngine？
 * - Flutter 引擎首次创建比较耗时（几百毫秒到 1 秒）
 * - 预加载后，打开 Flutter 页面几乎是秒开，用户体验好
 * - 多个 Flutter 页面可以共享同一个引擎，节省内存
 *
 * 多引擎 vs 共享引擎？
 * - 共享引擎：内存占用小，所有 Flutter 页面共享同一个 Dart isolate，状态天然共享
 * - 多引擎：每个页面独立引擎，隔离性好，但内存占用大，通信复杂
 * - 一般电商 App 用共享引擎足够，特殊场景（如独立的 Flutter 浮窗）才用多引擎
 */
object FlutterBridgeManager {

    private const val ENGINE_ID = "ecom_engine"
    private const val CHANNEL = "com.example.flutter_ecom/native_bridge"

    private lateinit var methodChannel: MethodChannel
    private lateinit var appContext: Context
    private var engine: FlutterEngine? = null

    /**
     * 预加载 Flutter 引擎
     * 建议在 Application.onCreate 或主页面初始化时调用
     *
     * 面试讲解点：
     * 什么时候预热引擎最合适？
     * - Application.onCreate：最早，但会拖慢 App 启动速度
     * - 主页面渲染完成后：不影响启动速度，但要控制好时机
     * - 用户点击入口前：最省资源，但需要预判用户行为
     * - 我们项目是在首页渲染完成后异步预热，平衡启动速度和 Flutter 页面打开速度
     */
    fun preloadEngine(context: Context) {
        // 如果引擎已经缓存了，直接返回
        if (FlutterEngineCache.getInstance().get(ENGINE_ID) != null) {
            return
        }
        appContext = context.applicationContext
        engine = FlutterEngine(appContext).apply {
            // 执行 Dart 入口函数（main 函数）
            dartExecutor.executeDartEntrypoint(
                DartExecutor.DartEntrypoint.createDefault()
            )
            // 注册 MethodChannel
            setupMethodChannel(this)
            // 缓存引擎，后续 FlutterActivity 可以直接取
            FlutterEngineCache.getInstance().put(ENGINE_ID, this)
        }
    }

    /**
     * 获取缓存的引擎 ID
     */
    fun getEngineId(): String = ENGINE_ID

    /**
     * 获取 MethodChannel（原生主动调用 Flutter 时用）
     */
    fun getMethodChannel(): MethodChannel? {
        if (!::methodChannel.isInitialized) return null
        return methodChannel
    }

    /**
     * 注册 MethodChannel 并处理 Flutter 调用原生的请求
     *
     * 面试讲解点：
     * MethodChannel 的线程模型：
     * - Flutter 调用原生：在主线程（UI 线程）回调
     * - 原生调用 Flutter：在主线程调用
     * - 所以不要在 MethodCallHandler 里做耗时操作，会阻塞 UI
     *
     * 为什么不用 BasicMessageChannel / EventChannel？
     * - MethodChannel：适合 RPC 式的方法调用，一问一答，我们的场景大部分是这种
     * - BasicMessageChannel：适合持续通信、半结构化数据
     * - EventChannel：适合原生主动向 Flutter 发送事件流（如推送、传感器）
     */
    private fun setupMethodChannel(engine: FlutterEngine) {
        methodChannel = MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)

        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                // ===== 通用方法 =====
                "getAppInfo" -> {
                    val info = mapOf(
                        "versionName" to "1.0.0",
                        "versionCode" to 1,
                        "channel" to "official",
                        "platform" to "Android"
                    )
                    result.success(info)
                }

                "toast" -> {
                    val message = call.argument<String>("message") ?: ""
                    Toast.makeText(appContext, message, Toast.LENGTH_SHORT).show()
                    result.success(null)
                }

                "navigateBack" -> {
                    // 面试讲解点：
                    // Flutter 页面请求返回，原生需要 finish 当前 FlutterActivity。
                    // 实际项目中怎么通知 Activity finish？
                    // 方式一：用 EventBus / LiveData 发送事件，Activity 订阅后 finish
                    // 方式二：在 MethodChannel 里持有 Activity 引用（容易内存泄漏，不推荐）
                    // 方式三：用 FlutterActivity 的 CustomEngine 模式，自己管理生命周期
                    // 我们项目用的是方式一，通过 Application 级别的事件总线通知
                    result.success(null)
                }

                // ===== 登录相关 =====
                "nativeLogin" -> {
                    // 面试讲解点：
                    // 混合开发中登录态的处理：
                    // 我们的方案是原生维护登录态，Flutter 通过 Channel 获取用户信息和 Token
                    // 好处是登录态统一，不会出现原生登录了 Flutter 还没登录的情况
                    // Flutter 侧拿到 Token 后缓存起来，后续请求自己加 header
                    // 当 Token 过期时，Flutter 通过 Channel 通知原生去刷新 Token
                    val userInfo = mapOf(
                        "userId" to "10001",
                        "token" to "mock_token_abc123",
                        "nickname" to "红松用户",
                        "avatar" to "https://example.com/avatar.png"
                    )
                    result.success(userInfo)
                }

                "getToken" -> {
                    // 从原生本地存储（如 SP / MMKV）获取 token
                    // 实际项目中这里读 SharedPreferences
                    result.success("mock_token_abc123")
                }

                "logout" -> {
                    // 清除原生登录态
                    // 实际项目中调用退出登录逻辑
                    result.success(null)
                }

                // ===== 支付相关 =====
                "aliPay" -> {
                    val orderId = call.argument<String>("orderId")
                    val payInfo = call.argument<String>("payInfo")
                    // 面试讲解点：
                    // 支付是典型的需要原生能力的场景：
                    // Flutter 调用 MethodChannel 发起支付 → 原生调用支付宝 SDK →
                    // 支付结果回调 → 通过 result 返回给 Flutter → Flutter 更新 UI
                    // 这里是异步操作，result.success() 可以在回调里调用
                    result.success("success")
                }

                // ===== 相机相关 =====
                "takePhoto" -> {
                    // 面试讲解点：
                    // 相机也是原生能力，Flutter 调起原生相机页面，
                    // 拍完照返回图片路径给 Flutter 显示和上传
                    result.success("/storage/emulated/0/DCIM/Camera/IMG_001.jpg")
                }

                // ===== 未实现的方法 =====
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    /**
     * 原生主动调用 Flutter 方法
     *
     * 示例场景：
     * - 原生登录状态变化，通知 Flutter 更新用户信息
     * - 原生收到推送，通知 Flutter 刷新消息列表
     * - 原生切换了主题/语言，通知 Flutter 跟随切换
     */
    fun invokeFlutterMethod(method: String, arguments: Any?, callback: ((Any?) -> Unit)? = null) {
        getMethodChannel()?.invokeMethod(method, arguments, object : MethodChannel.Result {
            override fun success(result: Any?) {
                callback?.invoke(result)
            }
            override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                callback?.invoke(null)
            }
            override fun notImplemented() {
                callback?.invoke(null)
            }
        })
    }

    /**
     * 销毁引擎
     *
     * 面试讲解点：
     * 一般不需要主动销毁，因为 App 退出时进程被杀掉，引擎自然释放。
     * 什么情况下需要主动销毁？
     * - Flutter 模块使用频率很低，用完就释放省内存
     * - 用户退出登录，需要清理 Flutter 侧的所有状态
     * - 内存紧张时按需释放
     *
     * 注意：销毁后下次打开 Flutter 页面需要重新创建引擎，会有启动耗时。
     */
    fun destroyEngine() {
        FlutterEngineCache.getInstance().remove(ENGINE_ID)
        engine?.destroy()
        engine = null
    }
}
