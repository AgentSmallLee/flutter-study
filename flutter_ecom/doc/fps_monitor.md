# Flutter FPS 监控方案汇总

本文整理了 Flutter 中监听/监控 FPS 的各种方案，从简单到自定义，从开发调试到线上监控。

---

## 目录

1. [快速目测：Performance Overlay](#1-快速目测performance-overlay)
2. [专业分析：Flutter DevTools](#2-专业分析flutter-devtools)
3. [自定义监听：SchedulerBinding 帧回调](#3-自定义监听schedulerbinding-帧回调)
4. [推荐方案：onReportTimings 帧耗时回调](#4-推荐方案onreporttimings-帧耗时回调)
5. [完整示例：悬浮 FPS 指示器](#5-完整示例悬浮-fps-指示器)
6. [线上监控：第三方 SDK](#6-线上监控第三方-sdk)
7. [方案对比总结](#7-方案对比总结)

---

## 1. 快速目测：Performance Overlay

最简单的 FPS 查看方式，开启后屏幕顶部显示 GPU/UI 线程的帧耗时图表。

### 使用方式

在 `MaterialApp` / `CupertinoApp` 中设置：

```dart
MaterialApp(
  showPerformanceOverlay: true,
  // ...
)
```

### 说明

- 图表上方为 **GPU 线程**（光栅化耗时），下方为 **UI 线程**（Dart build/layout/paint 耗时）
- 横向红色警戒线为 16.6ms（60fps 的单帧预算），超过即掉帧
- Profile 模式下数据最准确，Debug 模式仅供定性参考
- Release 模式无效

---

## 2. 专业分析：Flutter DevTools

官方性能调试工具，提供帧级别的详细分析。

### 启动方式

```bash
# 以 profile 模式运行（性能数据准确）
flutter run --profile

# 控制台输出 DevTools 地址，浏览器打开即可
# 形如：http://127.0.0.1:9100?uri=http://127.0.0.1:65432/abc123=/
```

也可以单独启动：

```bash
dart devtools
```

然后在页面中粘贴 Observatory 地址连接。

### Performance 面板

- **帧时序图**：每帧的 UI / Raster 耗时柱状图，红色为掉帧
- **CPU 火焰图**：函数级调用栈与耗时，定位具体瓶颈
- **增强追踪（Enhance Tracing）**：可额外开启 Widget builds / Layouts / Paints 追踪

### 配合使用的调试开关

在 `main()` 中设置，配合 DevTools Timeline 查看：

```dart
import 'package:flutter/rendering.dart';

void main() {
  // 追踪 Widget build 耗时
  debugProfileBuildsEnabled = true;

  // 打印所有 rebuild 的 Widget（控制台输出）
  debugPrintRebuildDirtyWidgets = true;

  // 追踪 Layout 耗时
  debugProfileLayoutsEnabled = true;

  // 追踪 Paint 耗时
  debugProfilePaintsEnabled = true;

  runApp(const MyApp());
}
```

### 注意事项

- **Flutter Inspector**（Widget 布局检查）仅在 Debug 模式可用
- 性能分析请使用 **Profile 模式**，数据最接近真实环境

---

## 3. 自定义监听：SchedulerBinding 帧回调

通过 `addPostFrameCallback` 统计每秒回调次数来估算 FPS。实现简单，但精度一般。

```dart
import 'package:flutter/scheduler.dart';

class SimpleFpsMonitor {
  int _frameCount = 0;
  int _lastTime = 0;
  int fps = 0;
  bool _running = false;
  final void Function(int fps)? onFpsUpdate;

  SimpleFpsMonitor({this.onFpsUpdate});

  void start() {
    _running = true;
    SchedulerBinding.instance.addPostFrameCallback(_onFrame);
  }

  void stop() {
    _running = false;
  }

  void _onFrame(Duration timestamp) {
    if (!_running) return;

    _frameCount++;
    final now = timestamp.inMilliseconds;

    if (_lastTime == 0) {
      _lastTime = now;
    } else if (now - _lastTime >= 1000) {
      fps = _frameCount;
      _frameCount = 0;
      _lastTime = now;
      onFpsUpdate?.call(fps);
    }

    SchedulerBinding.instance.addPostFrameCallback(_onFrame);
  }
}
```

### 缺点

- 只能统计 `build` 完成的帧数，不包含 raster（GPU）阶段
- 如果 UI 线程阻塞但 GPU 不阻塞，结果会失真
- 适合粗略估算，不适合精准性能分析

---

## 4. 推荐方案：onReportTimings 帧耗时回调

Flutter 提供的官方帧回调，每一帧完成后都会触发，能拿到完整的帧耗时数据（build / raster / total），是自定义 FPS 监控的推荐方式。

### 基础用法

```dart
import 'dart:ui';
import 'package:flutter/material.dart';

class FpsTracker {
  final List<FrameTiming> _timings = [];
  void Function(int fps)? onFpsChanged;

  void start() {
    PlatformDispatcher.instance.onReportTimings = _onTimings;
  }

  void stop() {
    PlatformDispatcher.instance.onReportTimings = null;
  }

  void _onTimings(List<FrameTiming> timings) {
    _timings.addAll(timings);

    // 只保留最近 1 秒的帧数据
    final now = DateTime.now().millisecondsSinceEpoch;
    _timings.removeWhere(
      (t) => now - t.timestamp.inMilliseconds > 1000,
    );

    final fps = _timings.length;
    onFpsChanged?.call(fps);
  }
}
```

### FrameTiming 字段说明

| 字段 | 含义 |
|------|------|
| `timestamp` | 帧开始时间 |
| `buildDuration` | build 阶段耗时（UI 线程） |
| `rasterDuration` | raster 阶段耗时（GPU 线程） |
| `totalSpan` | 总耗时 = build + raster |
| `buildStart` / `buildFinish` | build 起止时间戳 |
| `rasterStart` / `rasterFinish` | raster 起止时间戳 |

### 更精细的 FPS 统计

区分 UI 线程 FPS 和 GPU 线程 FPS：

```dart
void _onTimings(List<FrameTiming> timings) {
  int slowFrames = 0;
  const frameBudget = Duration(microseconds: 16667); // ~16.6ms

  for (final timing in timings) {
    final total = timing.buildDuration + timing.rasterDuration;
    if (total > frameBudget) {
      slowFrames++;
    }
  }
  // 上报掉帧数、平均帧耗时等
}
```

### 注意事项

- 使用 `PlatformDispatcher.instance.onReportTimings` 而非 `window.onReportTimings`（Flutter 3.x 后 `window` 已废弃）
- 此回调在 Profile 和 Debug 模式下可用，Release 模式下为空
- 同一时间只能有一个回调，后设置的会覆盖前一个

---

## 5. 完整示例：悬浮 FPS 指示器

一个可直接使用的悬浮 FPS 显示 Widget，debug 模式自动显示，release 模式无 overhead。

```dart
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 悬浮 FPS 指示器
///
/// 仅在 debug 模式下显示，release 模式直接返回 child，无性能损耗。
class FpsOverlay extends StatefulWidget {
  final Widget child;
  final bool show;

  const FpsOverlay({
    super.key,
    required this.child,
    this.show = kDebugMode,
  });

  @override
  State<FpsOverlay> createState() => _FpsOverlayState();
}

class _FpsOverlayState extends State<FpsOverlay> {
  int _fps = 0;
  double _avgFrameMs = 0;
  final List<FrameTiming> _timings = [];
  static const int _maxFrames = 120; // 最多保留 120 帧（约 2 秒 @60fps）

  @override
  void initState() {
    super.initState();
    if (widget.show) {
      PlatformDispatcher.instance.onReportTimings = _onTimings;
    }
  }

  @override
  void dispose() {
    if (widget.show) {
      PlatformDispatcher.instance.onReportTimings = null;
    }
    super.dispose();
  }

  void _onTimings(List<FrameTiming> timings) {
    _timings.addAll(timings);

    // 只保留最近 _maxFrames 帧
    if (_timings.length > _maxFrames) {
      _timings.removeRange(0, _timings.length - _maxFrames);
    }

    // 计算 FPS（最近 1 秒内的帧数）
    final now = DateTime.now().millisecondsSinceEpoch;
    final framesInSecond = _timings.where(
      (t) => now - t.timestamp.inMilliseconds <= 1000,
    ).length;

    // 计算平均帧耗时
    if (_timings.isNotEmpty) {
      final total = _timings.fold<int>(
        0,
        (sum, t) => sum + (t.buildDuration + t.rasterDuration).inMicroseconds,
      );
      _avgFrameMs = total / _timings.length / 1000;
    }

    if (mounted) {
      setState(() {
        _fps = framesInSecond;
      });
    }
  }

  Color get _fpsColor {
    if (_fps >= 55) return Colors.green;
    if (_fps >= 30) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.show) return widget.child;

    return Stack(
      children: [
        widget.child,
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          right: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FPS: $_fps',
                  style: TextStyle(
                    color: _fpsColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'avg: ${_avgFrameMs.toStringAsFixed(1)}ms',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
```

### 使用方式

```dart
import 'package:flutter/foundation.dart';

void main() {
  runApp(
    const FpsOverlay(
      child: MyApp(),
    ),
  );
}
```

默认 `kDebugMode` 下显示，release 自动隐藏。

---

## 6. 线上监控：第三方 SDK

线上用户真实设备的 FPS 监控，需要接入 APM（应用性能监控）SDK：

| SDK | 说明 |
|-----|------|
| **腾讯 Bugly** | 支持 Flutter 性能监控（FPS、启动耗时、内存等） |
| **听云** | 国内老牌 APM，Flutter 插件支持较好 |
| **阿里云 ARMS** | 阿里云应用监控，Flutter 适配中 |
| **Sentry** | 国外主流异常监控，也支持性能指标采集 |
| **Firebase Performance** | Google 官方，需配合 Flutter 插件使用 |
| **自研上报** | 基于 `onReportTimings` + 自己的后端服务 |

### 自研上报思路

```dart
void startOnlineFpsReport() {
  PlatformDispatcher.instance.onReportTimings = (timings) {
    // 1. 累加掉帧数
    // 2. 每隔 30 秒 / 页面退出时上报一次
    // 3. 上报字段：页面名、平均FPS、掉帧数、最大单帧耗时
  };
}
```

---

## 7. 方案对比总结

| 方案 | 准确度 | 自定义程度 | 适用场景 | 模式要求 |
|------|--------|-----------|---------|---------|
| `showPerformanceOverlay` | 高 | 低 | 快速目测是否掉帧 | Debug / Profile |
| DevTools Performance | 最高 | 中 | 深度性能分析、定位瓶颈 | Debug / Profile |
| `SchedulerBinding` 回调 | 一般 | 高 | 简单 FPS 估算、轻量需求 | Debug / Profile |
| `onReportTimings` 自定义 | 高 | 高 | 自定义 FPS 显示、自研上报 | Debug / Profile |
| 第三方 APM SDK | 高 | 中 | 线上真实用户性能监控 | Release |

### 推荐使用场景

- **开发调试阶段** → `showPerformanceOverlay` + DevTools 配合使用
- **需要在 App 内直观看到 FPS 数字** → 自定义 `FpsOverlay`（基于 `onReportTimings`）
- **线上版本性能监控** → 接入第三方 APM SDK 或自研上报
