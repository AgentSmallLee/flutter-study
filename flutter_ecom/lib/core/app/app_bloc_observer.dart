import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../utils/logger.dart';

/// Bloc 全局观察者
///
/// 监听所有 Bloc 的状态变化、事件派发和错误，统一日志输出。
///
/// 面试讲解点：
/// BlocObserver 是 bloc 库提供的全局钩子，
/// 可以在这里做埋点统计、错误上报、调试日志等横切关注点。
class AppBlocObserver extends BlocObserver {
  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    AppLogger.d('Bloc created: ${bloc.runtimeType}');
  }

  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    AppLogger.d('Bloc event: ${bloc.runtimeType} → ${event.runtimeType}');
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    AppLogger.d(
      'Bloc change: ${bloc.runtimeType}\n'
      '  from: ${change.currentState.runtimeType}\n'
      '  to:   ${change.nextState.runtimeType}',
    );
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    if (kDebugMode) {
      AppLogger.i(
        'Bloc transition: ${bloc.runtimeType}\n'
        '  event: ${transition.event.runtimeType}\n'
        '  from:  ${transition.currentState.runtimeType}\n'
        '  to:    ${transition.nextState.runtimeType}',
      );
    }
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    AppLogger.e(
      'Bloc error: ${bloc.runtimeType}',
      error,
      stackTrace,
    );
  }

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);
    AppLogger.d('Bloc closed: ${bloc.runtimeType}');
  }
}
