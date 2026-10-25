# Flutter ShellRoute 详解（基于 go_router）

## 一、ShellRoute 是什么

`ShellRoute` 是 **go_router** 提供的一种**嵌套路由容器**，它的作用是：

> 在一组子路由的**外层包裹一个共享的 UI 壳（Shell）**，子路由切换时，外层壳**保持不变、不会重建**。

最典型的应用场景就是**底部导航栏（BottomNavigationBar）**——切换首页/分类/购物车/我的时，底部导航栏始终存在，只有中间内容区切换。

---

## 二、在本项目中的具体应用

项目文件：`flutter_ecom/lib/core/router/app_router.dart`

### 2.1 路由结构

```
GoRouter (根导航 _rootNavigatorKey)
├── ShellRoute (Shell导航 _shellNavigatorKey)
│   ├── MainShell (Scaffold + BottomNavigationBar)
│   │   ├── /home     → HomePage
│   │   ├── /category → CategoryPage
│   │   ├── /cart     → CartPage
│   │   └── /profile  → ProfilePage
├── /login           → LoginPage          (全屏，无底部导航)
├── /product/:id     → ProductDetailPage  (全屏，无底部导航)
├── /search          → SearchPage         (全屏，无底部导航)
├── /orders          → OrderListPage      (全屏，无底部导航)
├── /order/:id       → OrderDetailPage    (全屏，无底部导航)
├── /register        → RegisterPage       (全屏，无底部导航)
└── /settings        → SettingsPage       (全屏，无底部导航)
```

### 2.2 核心代码

```dart
// 两个导航器 Key
static final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
static final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');

// ShellRoute 配置
ShellRoute(
  navigatorKey: _shellNavigatorKey,
  builder: (context, state, child) {
    return MainShell(child: child);  // child 是当前激活的子路由页面
  },
  routes: [
    GoRoute(path: '/home', ...),
    GoRoute(path: '/category', ...),
    GoRoute(path: '/cart', ...),
    GoRoute(path: '/profile', ...),
  ],
),

// 全屏页面走根导航器
GoRoute(
  path: '/product/:id',
  name: 'product_detail',
  builder: (context, state) => ProductDetailPage(...),
  parentNavigatorKey: _rootNavigatorKey,  // 关键：指定走根导航器
),
```

---

## 三、核心机制解析

### 3.1 两个 Navigator 各司其职

| Navigator | Key | 职责 |
|-----------|-----|------|
| Shell Navigator | `_shellNavigatorKey` | 管理 4 个底部 Tab 页面的切换，底部导航栏常驻 |
| Root Navigator | `_rootNavigatorKey` | 管理全屏页面的 push/pop，覆盖整个屏幕 |

- Shell 内部的子路由（`/home`、`/category` 等）默认走 **Shell Navigator**
- 标记了 `parentNavigatorKey: _rootNavigatorKey` 的路由走 **Root Navigator**，以**全屏方式**打开，底部导航栏也会被遮住

### 3.2 MainShell 的 child 参数

`ShellRoute` 的 `builder` 回调接收三个参数：

```dart
builder: (context, state, child) {
  return MainShell(child: child);
}
```

- `context` —— 构建上下文
- `state` —— 当前路由状态（`GoRouterState`）
- `child` —— **当前激活的子路由 Widget**（如 `HomePage`、`CategoryPage`）

切换 Tab 时，`child` 变化，但 `MainShell`（包括 `BottomNavigationBar`）不会整体重建，只有 `body` 区域的内容替换。

### 3.3 Tab 切换的实现

```dart
void _onItemTapped(int index) {
  setState(() => _currentIndex = index);
  context.go(_navItems[index].path);  // 通过 go_router 声明式切换
}
```

点击底部导航调用 `context.go()`，由 go_router 负责匹配路由、切换 `child` 内容。`_currentIndex` 只用于控制底部导航栏的高亮状态。

---

## 四、ShellRoute vs IndexedStack

这是面试高频对比题。

| 对比项 | ShellRoute + go_router | IndexedStack |
|--------|----------------------|--------------|
| 页面状态保留 | **不保留**，切换后页面销毁重建（除非加 PageStorageKey） | **保留**，所有页面同时存在内存中 |
| 内存占用 | 低，一次只渲染一个页面 | 高，所有 Tab 页面常驻内存 |
| 深链接支持 | 原生支持，URL 直接对应 Tab | 不支持，需要自己处理 |
| 路由跳转 | `context.go('/cart')` 声明式 | 手动 setState 切 index |
| 嵌套导航 | 天然支持，子路由有独立导航栈 | 需要自己管理嵌套 Navigator |
| 动画控制 | 可通过 NoTransitionPage 去掉动画 | 无切换动画 |
| 适用场景 | 页面多、有深链接需求、追求声明式路由 | Tab 少（<5）、需要无缝切换保留状态 |

> **本项目选择 ShellRoute 的原因**：电商 App 页面多、需要深链接（商品分享链接直接打开）、使用 go_router 统一路由管理，声明式更清晰。

---

## 五、本项目的额外亮点

### 5.1 购物车角标的细粒度刷新

`MainShell` 中购物车图标使用 `BlocSelector` 只监听 `totalCount` 字段：

```dart
BottomNavigationBarItem(
  icon: BlocSelector<CartBloc, CartState, int>(
    bloc: getIt<CartBloc>(),
    selector: (state) => state.totalCount,  // 只取购物车商品总数
    builder: (context, count) {
      return _CartBadgeIcon(icon: e.icon, count: count);
    },
  ),
  ...
)
```

**原理**：`BlocSelector` 只订阅状态的一部分（`totalCount`），只有这部分变化时才重新构建。

**好处**：购物车其他状态变化（如商品选中状态、总价变化）不会触发底部导航栏重建，只有总数变化才刷新角标。底部导航是全局组件，减少它的重建次数对整体性能有帮助。

### 5.2 NoTransitionPage 避免切换动画

```dart
GoRoute(
  path: '/home',
  name: 'home',
  pageBuilder: (context, state) => const NoTransitionPage(
    child: HomePage(),
  ),
),
```

Tab 切换使用 `NoTransitionPage`，去掉页面切换的过渡动画，体验更接近原生底部导航的切换效果。

### 5.3 认证状态驱动路由刷新

```dart
refreshListenable: _AuthStateListenable(),

class _AuthStateListenable extends ChangeNotifier {
  _AuthStateListenable() {
    _authSubscription = getIt<AuthBloc>().stream.listen((_) {
      notifyListeners();  // 认证状态变化时触发路由重评估
    });
  }
}
```

通过 `refreshListenable` 绑定 `AuthBloc` 的状态流，当登录/登出时自动触发 `redirect` 回调重新判断路由权限。

---

## 六、常见问题与解决方案

### Q1：ShellRoute 切换时页面状态丢失怎么办？

ShellRoute 切换时默认页面会销毁重建，保留状态的方案：

1. **`PageStorageKey`** —— 保存滚动位置、表单输入等临时状态
   ```dart
   ListView(key: const PageStorageKey('home_list'), ...)
   ```

2. **`AutomaticKeepAliveClientMixin`** —— 保持页面存活不销毁
   ```dart
   class _HomePageState extends State<HomePage> with AutomaticKeepAliveClientMixin {
     @override
     bool get wantKeepAlive => true;
   }
   ```

3. **状态上提** —— 用 Bloc / Provider 等全局状态管理保存业务数据，页面重建时从状态中恢复

### Q2：为什么商品详情页不走 ShellRoute？

商品详情是全屏页面，不需要底部导航栏，所以指定 `parentNavigatorKey: _rootNavigatorKey`，让它走根导航器，以全屏方式覆盖在 Shell 之上。

### Q3：ShellRoute 支持嵌套多级吗？

支持。可以在 ShellRoute 的子路由里再嵌套 ShellRoute，实现多层级的壳布局（比如侧栏菜单 + 底部导航的组合）。

---

## 七、面试常见问题汇总

**Q：ShellRoute 和 IndexedStack 有什么区别？**
> ShellRoute 是 go_router 的嵌套路由方案，一次只渲染一个页面，支持深链接和声明式路由，但页面切换会重建。IndexedStack 同时加载所有页面常驻内存，状态天然保留，但不支持深链接，内存占用高。

**Q：ShellRoute 有几个 Navigator？**
> 至少两个：一个 root Navigator（根导航），一个 shell Navigator（壳导航）。Shell 内部的子路由走 shell Navigator，全屏页面走 root Navigator，通过 `parentNavigatorKey` 指定。

**Q：用 ShellRoute 时页面切回来状态丢失怎么办？**
> 三种方案：① 使用 `PageStorageKey` 保存滚动位置等状态；② 用 `AutomaticKeepAliveClientMixin` 保持页面存活；③ 状态上提到 Bloc/Provider 等全局状态管理中。

**Q：go_router 中 ShellRoute 的 builder 里的 child 是什么？**
> child 是当前激活的子路由 Widget。切换 Tab 时 child 变化，但 Shell 外层布局（如底部导航栏）不会整体重建，只有 child 对应的内容区域替换。
