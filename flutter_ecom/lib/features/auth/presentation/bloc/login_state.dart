part of 'login_bloc.dart';

class LoginState extends Equatable {
  const LoginState({
    this.phone = '',
    this.password = '',
    this.phoneError,
    this.passwordError,
    this.obscurePassword = true,
    this.isSubmitting = false,
    this.isSuccess = false,
    this.errorMessage,
    this.user,
  });

  final String phone;
  final String password;
  final String? phoneError;
  final String? passwordError;
  final bool obscurePassword;
  final bool isSubmitting;
  final bool isSuccess;
  final String? errorMessage;
  final UserEntity? user;

  /// 表单是否有效（用于按钮是否可点击）
  bool get isFormValid =>
      phone.isValidPhone && password.length >= 6 && !isSubmitting;

  LoginState copyWith({
    String? phone,
    String? password,
    String? phoneError,
    String? passwordError,
    bool? obscurePassword,
    bool? isSubmitting,
    bool? isSuccess,
    String? errorMessage,
    UserEntity? user,
    bool clearError = false,
  }) {
    return LoginState(
      phone: phone ?? this.phone,
      password: password ?? this.password,
      phoneError: clearError ? null : (phoneError ?? this.phoneError),
      passwordError:
          clearError ? null : (passwordError ?? this.passwordError),
      obscurePassword: obscurePassword ?? this.obscurePassword,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      user: user ?? this.user,
    );
  }

  @override
  List<Object?> get props => [
        phone,
        password,
        phoneError,
        passwordError,
        obscurePassword,
        isSubmitting,
        isSuccess,
        errorMessage,
        user,
      ];
}
