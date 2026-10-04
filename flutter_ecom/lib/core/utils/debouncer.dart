/// 防抖工具类
///
/// 用于搜索输入等频繁触发的场景，避免短时间内多次请求。
///
/// 面试讲解点：
/// 防抖（debounce）和节流（throttle）的区别：
/// - 防抖：连续触发时只执行最后一次（如搜索输入）
/// - 节流：固定时间间隔内只执行一次（如按钮防重复点击）
class Debouncer {
  Debouncer({this.duration = const Duration(milliseconds: 500)});

  final Duration duration;
  DateTime? _lastActionTime;

  /// 执行防抖操作
  /// 多次调用时，只有最后一次会在 [duration] 后真正执行
  void call(void Function() action) {
    _lastActionTime = DateTime.now();
    Future.delayed(duration, () {
      if (_lastActionTime != null &&
          DateTime.now().difference(_lastActionTime!) >= duration) {
        action();
      }
    });
  }

  /// 取消待执行的操作
  void cancel() {
    _lastActionTime = null;
  }
}
