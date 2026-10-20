import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/app/app_bloc_observer.dart';
import 'core/di/service_locator.dart';
import 'core/utils/logger.dart';

/// App 入口函数
///
/// 面试讲解点：
/// main 函数中完成所有全局初始化：
/// 1. WidgetsFlutterBinding - 确保 Flutter 引擎初始化完成
/// 2. Bloc.observer - 全局 Bloc 状态监听
/// 3. Hive.initFlutter - 本地数据库初始化
/// 4. configureDependencies - 依赖注入初始化
/// 5. runApp - 启动 App
Future<void> main() async {
  debugProfileBuildsEnabled = true;
  // 确保 Flutter 引擎绑定完成
  WidgetsFlutterBinding.ensureInitialized();

  // 设置全局 Bloc 观察者
  Bloc.observer = AppBlocObserver();

  try {
    // 初始化 Hive 本地存储
    await Hive.initFlutter();

    // 初始化依赖注入
    await configureDependencies();

    AppLogger.i('App initialized successfully');
  } catch (e, stackTrace) {
    AppLogger.e('App initialization failed', e, stackTrace);
  }

  // 启动 App
  runApp(const MyApp());
}
