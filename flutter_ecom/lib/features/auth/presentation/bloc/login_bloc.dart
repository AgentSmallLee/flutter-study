import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/extensions/string_extensions.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/login_usecase.dart';

part 'login_event.dart';
part 'login_state.dart';

/// 登录页 Bloc
///
/// 面试讲解点：
/// 表单验证为什么放在 Bloc 里而不是 UI 里？
/// 1. 业务逻辑和 UI 分离，便于单元测试
/// 2. 验证规则可以复用（注册页也有类似验证）
/// 3. 状态变化可追踪（配合 BlocObserver 可以看到所有输入的变化）
///
/// 状态设计包含每个字段的错误信息，UI 根据错误信息展示红色提示。
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc(this._loginUseCase) : super(const LoginState()) {
    on<LoginPhoneChanged>(_onPhoneChanged);
    on<LoginPasswordChanged>(_onPasswordChanged);
    on<LoginSubmitted>(_onSubmitted);
    on<LoginObscureToggled>(_onObscureToggled);
  }

  final LoginUseCase _loginUseCase;

  void _onPhoneChanged(LoginPhoneChanged event, Emitter<LoginState> emit) {
    final phone = event.phone;
    final phoneError = _validatePhone(phone);
    emit(state.copyWith(
      phone: phone,
      phoneError: phoneError,
    ));
  }

  void _onPasswordChanged(
    LoginPasswordChanged event,
    Emitter<LoginState> emit,
  ) {
    final password = event.password;
    final passwordError = _validatePassword(password);
    emit(state.copyWith(
      password: password,
      passwordError: passwordError,
    ));
  }

  void _onObscureToggled(
    LoginObscureToggled event,
    Emitter<LoginState> emit,
  ) {
    emit(state.copyWith(obscurePassword: !state.obscurePassword));
  }

  Future<void> _onSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    // 提交前做最终验证
    final phoneError = _validatePhone(state.phone);
    final passwordError = _validatePassword(state.password);

    if (phoneError != null || passwordError != null) {
      emit(state.copyWith(
        phoneError: phoneError,
        passwordError: passwordError,
      ));
      return;
    }

    emit(state.copyWith(isSubmitting: true, errorMessage: null));

    final result = await _loginUseCase(
      phone: state.phone,
      password: state.password,
    );

    result.fold(
      (failure) {
        emit(state.copyWith(
          isSubmitting: false,
          errorMessage: failure.message,
        ));
      },
      (user) {
        emit(state.copyWith(
          isSubmitting: false,
          isSuccess: true,
          user: user,
        ));
      },
    );
  }

  /// 验证手机号
  String? _validatePhone(String phone) {
    if (phone.isEmpty) return '请输入手机号';
    if (!phone.isValidPhone) return '请输入正确的手机号';
    return null;
  }

  /// 验证密码
  String? _validatePassword(String password) {
    if (password.isEmpty) return '请输入密码';
    if (password.length < 6) return '密码长度不能少于6位';
    return null;
  }
}
