import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/service_locator.dart';
import 'core/resources/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/cart/presentation/bloc/cart_bloc.dart';

/// 根 Widget
///
/// 面试讲解点：
/// 使用 MultiBlocProvider 在 App 顶层提供全局单例 Bloc：
/// - AuthBloc：全局登录状态，路由守卫依赖它
/// - CartBloc：全局购物车状态，底部导航徽标、商品详情等多处共享
///
/// 这样任何子 Widget 都可以通过 context.read<AuthBloc>() / context.watch<CartBloc>()
/// 获取全局状态，而不需要层层传递。
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // 全局认证状态
        BlocProvider<AuthBloc>.value(value: getIt<AuthBloc>()),
        // 全局购物车状态
        BlocProvider<CartBloc>.value(value: getIt<CartBloc>()),
      ],
      child: MaterialApp.router(
        title: 'FlutterEcom',
        debugShowCheckedModeBanner: false,
        showPerformanceOverlay: true,
        // 主题
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        // 路由
        routerConfig: AppRouter.router,
        // 滚动行为
        scrollBehavior: const MaterialScrollBehavior(),
      ),
    );
  }
}
