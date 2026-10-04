import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/button/primary_button.dart';
import '../../domain/entities/user_entity.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/login_bloc.dart';

/// 登录页
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<LoginBloc>(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('登录'),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimens.spacingXL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppDimens.spacingXXL),
              // Logo / 标题
              const Center(
                child: Icon(
                  Icons.shopping_bag,
                  size: 64,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppDimens.spacingM),
              const Center(
                child: Text(
                  'FlutterEcom',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.spacingXXL * 2),
              // 手机号输入框
              BlocBuilder<LoginBloc, LoginState>(
                builder: (context, state) {
                  return TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    maxLength: 11,
                    decoration: InputDecoration(
                      labelText: '手机号',
                      hintText: '请输入手机号',
                      prefixIcon: const Icon(Icons.phone_android),
                      errorText: state.phoneError,
                      counterText: '',
                    ),
                    onChanged: (value) => context
                        .read<LoginBloc>()
                        .add(LoginPhoneChanged(value)),
                  );
                },
              ),
              const SizedBox(height: AppDimens.spacingL),
              // 密码输入框
              BlocBuilder<LoginBloc, LoginState>(
                builder: (context, state) {
                  return TextField(
                    controller: _passwordController,
                    obscureText: state.obscurePassword,
                    maxLength: 20,
                    decoration: InputDecoration(
                      labelText: '密码',
                      hintText: '请输入密码',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          state.obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: AppColors.textHint,
                        ),
                        onPressed: () => context
                            .read<LoginBloc>()
                            .add(const LoginObscureToggled()),
                      ),
                      errorText: state.passwordError,
                      counterText: '',
                    ),
                    onChanged: (value) => context
                        .read<LoginBloc>()
                        .add(LoginPasswordChanged(value)),
                  );
                },
              ),
              const SizedBox(height: AppDimens.spacingM),
              // 错误提示
              BlocBuilder<LoginBloc, LoginState>(
                builder: (context, state) {
                  if (state.errorMessage == null) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppDimens.spacingM),
                    child: Container(
                      padding: const EdgeInsets.all(AppDimens.spacingS),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppDimens.radiusS),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppColors.error,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              state.errorMessage!,
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: AppDimens.fontS,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              // 登录按钮
              BlocConsumer<LoginBloc, LoginState>(
                listener: (context, state) {
                  if (state.isSuccess && state.user != null) {
                    // 登录成功：更新全局 AuthBloc 状态
                    context.read<AuthBloc>().add(
                          AuthLoggedIn(state.user!),
                        );
                    // 跳转到"我的"页面（替换当前路由，避免返回闪烁）
                    context.go('/profile');
                  }
                },
                builder: (context, state) {
                  return PrimaryButton(
                    text: '登录',
                    isLoading: state.isSubmitting,
                    isEnabled: state.isFormValid,
                    onPressed: () => context
                        .read<LoginBloc>()
                        .add(const LoginSubmitted()),
                  );
                },
              ),
              const SizedBox(height: AppDimens.spacingL),
              // 注册跳转
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '还没有账号？',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: AppDimens.fontM,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // TODO: 跳转到注册页
                    },
                    child: const Text('立即注册'),
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.spacingL),
              // Demo 提示
              const Center(
                child: Text(
                  '演示账号：任意手机号 + 任意6位以上密码',
                  style: TextStyle(
                    color: AppColors.textHint,
                    fontSize: AppDimens.fontS,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
