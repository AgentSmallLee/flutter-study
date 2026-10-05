import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/cart/presentation/bloc/cart_bloc.dart';
import '../../features/cart/presentation/bloc/cart_state.dart';
import '../../features/cart/presentation/pages/cart_page.dart';
import '../../features/category/presentation/pages/category_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/product_detail/presentation/pages/product_detail_page.dart';
import '../../features/order/presentation/pages/order_detail_page.dart';
import '../../features/order/presentation/pages/order_list_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../di/service_locator.dart';

/// 应用路由配置
///
/// 使用 go_router 的 ShellRoute 实现底部导航嵌套路由。
///
/// 面试讲解点：
/// go_router 是 Flutter 官方推荐的声明式路由，
/// 支持嵌套导航（ShellRoute）、路由守卫（redirect）、深链接等。
class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');
  static final GlobalKey<NavigatorState> _shellNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'shell');

  static GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    debugLogDiagnostics: true,
    refreshListenable: _AuthStateListenable(),
    redirect: (context, state) {
      // 路由守卫逻辑（后续完善，现在返回 null 表示不拦截）
      return null;
    },
    routes: [
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return MainShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomePage(),
            ),
          ),
          GoRoute(
            path: '/category',
            name: 'category',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CategoryPage(),
            ),
          ),
          GoRoute(
            path: '/cart',
            name: 'cart',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CartPage(),
            ),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfilePage(),
            ),
          ),
        ],
      ),
      // ============ 非底部导航页面 ============
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
        parentNavigatorKey: _rootNavigatorKey,
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('注册')),
          body: const Center(child: Text('注册页面')),
        ),
        parentNavigatorKey: _rootNavigatorKey,
      ),
      GoRoute(
        path: '/product/:id',
        name: 'product_detail',
        builder: (context, state) {
          final productId =
              int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return ProductDetailPage(productId: productId);
        },
        parentNavigatorKey: _rootNavigatorKey,
      ),
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (context, state) => const SearchPage(),
        parentNavigatorKey: _rootNavigatorKey,
      ),
      GoRoute(
        path: '/orders',
        name: 'orders',
        builder: (context, state) {
          // 支持通过 query 参数传递初始状态
          final statusStr = state.uri.queryParameters['status'];
          final status =
              statusStr != null ? int.tryParse(statusStr) : null;
          return OrderListPage(initialStatus: status);
        },
        parentNavigatorKey: _rootNavigatorKey,
      ),
      GoRoute(
        path: '/order/:id',
        name: 'order_detail',
        builder: (context, state) {
          final orderId = state.pathParameters['id'] ?? '';
          return OrderDetailPage(orderId: orderId);
        },
        parentNavigatorKey: _rootNavigatorKey,
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('设置')),
          body: const Center(child: Text('设置页面')),
        ),
        parentNavigatorKey: _rootNavigatorKey,
      ),
    ],
  );
}

/// 认证状态监听器
///
/// 用于 go_router 的 refreshListenable，
/// 当 AuthBloc 状态变化时，触发路由重新评估 redirect 回调。
class _AuthStateListenable extends ChangeNotifier {
  _AuthStateListenable() {
    _authSubscription = getIt<AuthBloc>().stream.listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }
}

/// 主框架 Shell（底部导航 + 内容区）
class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  static const List<_NavItem> _navItems = [
    _NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: '首页',
      path: '/home',
    ),
    _NavItem(
      icon: Icons.category_outlined,
      activeIcon: Icons.category,
      label: '分类',
      path: '/category',
    ),
    _NavItem(
      icon: Icons.shopping_cart_outlined,
      activeIcon: Icons.shopping_cart,
      label: '购物车',
      path: '/cart',
    ),
    _NavItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: '我的',
      path: '/profile',
    ),
  ];

  void _onItemTapped(int index) {
    setState(() => _currentIndex = index);
    context.go(_navItems[index].path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        items: _navItems.map((e) {
          if (e.label == '购物车') {
            // 面试讲解点：
            // 底部导航购物车角标使用 BlocSelector 细粒度刷新，
            // 只监听 totalCount 字段。购物车其他状态变化（如选中状态、总价）
            // 不会触发底部导航的重建，避免不必要的性能开销。
            // 底部导航是全局组件，减少它的重建次数对整体性能有帮助。
            return BottomNavigationBarItem(
              icon: BlocSelector<CartBloc, CartState, int>(
                bloc: getIt<CartBloc>(),
                selector: (state) => state.totalCount,
                builder: (context, count) {
                  return _CartBadgeIcon(icon: e.icon, count: count);
                },
              ),
              activeIcon: BlocSelector<CartBloc, CartState, int>(
                bloc: getIt<CartBloc>(),
                selector: (state) => state.totalCount,
                builder: (context, count) {
                  return _CartBadgeIcon(
                    icon: e.activeIcon,
                    count: count,
                    isActive: true,
                  );
                },
              ),
              label: e.label,
            );
          }
          return BottomNavigationBarItem(
            icon: Icon(e.icon),
            activeIcon: Icon(e.activeIcon),
            label: e.label,
          );
        }).toList(),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.path,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;
}

/// 购物车徽标图标
class _CartBadgeIcon extends StatelessWidget {
  const _CartBadgeIcon({
    required this.icon,
    required this.count,
    this.isActive = false,
  });

  final IconData icon;
  final int count;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (count > 0)
          Positioned(
            right: -8,
            top: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              constraints: const BoxConstraints(minWidth: 16),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count > 99 ? '99+' : '$count',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
