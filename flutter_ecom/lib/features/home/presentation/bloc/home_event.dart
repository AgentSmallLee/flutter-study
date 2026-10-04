import 'package:equatable/equatable.dart';

/// 首页事件
///
/// 面试讲解点：
/// Bloc 是事件驱动的：UI 发出 Event → Bloc 处理 → 发出 State。
/// 所有事件都继承自 HomeEvent，用 sealed class 风格（手动实现）做类型区分，
/// 处理时用 switch 或 is 检查。
///
/// 使用 Equatable 是为了值比较，相同的事件不会重复触发。
abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object> get props => [];
}

/// 初始加载事件（首次进入页面）
class HomeInitialEvent extends HomeEvent {
  const HomeInitialEvent();
}

/// 下拉刷新事件
class HomeRefreshEvent extends HomeEvent {
  const HomeRefreshEvent();
}

/// 加载更多商品事件
class HomeLoadMoreEvent extends HomeEvent {
  const HomeLoadMoreEvent();
}
