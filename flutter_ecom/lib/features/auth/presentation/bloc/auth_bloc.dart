import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// 全局认证 Bloc
///
/// 面试讲解点：
/// AuthBloc 是全局单例，管理整个 App 的登录状态。
/// 它和 go_router 配合实现路由守卫：
/// - 未登录时访问需要登录的页面 → 跳转到登录页
/// - 登录成功后 → 返回原页面
///
/// 状态设计为三种：
/// - AuthInitial：正在检查本地登录状态
/// - Authenticated：已登录
/// - Unauthenticated：未登录
///
/// 这种设计可以避免 App 启动时的登录页闪烁问题
/// （启动时先展示 Splash/Loading，判断完登录状态再跳转）。
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required GetCurrentUserUseCase getCurrentUserUseCase,
    required LogoutUseCase logoutUseCase,
  })  : _getCurrentUserUseCase = getCurrentUserUseCase,
        _logoutUseCase = logoutUseCase,
        super(const AuthInitial()) {
    on<AuthCheckStatus>(_onCheckStatus);
    on<AuthLoggedIn>(_onLoggedIn);
    on<AuthLoggedOut>(_onLoggedOut);
  }

  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final LogoutUseCase _logoutUseCase;

  /// 检查登录状态（启动时调用）
  Future<void> _onCheckStatus(
    AuthCheckStatus event,
    Emitter<AuthState> emit,
  ) async {
    // 模拟轻微延迟（实际读取本地存储很快）
    await Future.delayed(const Duration(milliseconds: 300));
    final user = await _getCurrentUserUseCase();
    if (user != null) {
      emit(Authenticated(user));
    } else {
      emit(const Unauthenticated());
    }
  }

  /// 登录成功事件（LoginBloc 登录成功后发出）
  Future<void> _onLoggedIn(
    AuthLoggedIn event,
    Emitter<AuthState> emit,
  ) async {
    emit(Authenticated(event.user));
  }

  /// 登出事件
  Future<void> _onLoggedOut(
    AuthLoggedOut event,
    Emitter<AuthState> emit,
  ) async {
    await _logoutUseCase();
    emit(const Unauthenticated());
  }
}
