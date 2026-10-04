import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/extensions/num_extensions.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

/// 个人中心页面
///
/// 面试讲解点：
/// 个人中心根据全局 AuthBloc 的状态展示不同的 UI：
/// - 未登录：展示登录入口
/// - 已登录：展示用户信息、订单、功能列表
///
/// 头像、用户名等信息都来自 AuthBloc 的全局状态，
/// 登录成功后这里会自动更新（因为是同一个 Bloc）。
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final isLoggedIn = state is Authenticated;
          final user = state is Authenticated ? state.user : null;
          return CustomScrollView(
            slivers: [
              // 顶部用户信息
              SliverToBoxAdapter(
                child: _buildHeader(context, isLoggedIn, user),
              ),
              // 订单中心
              SliverToBoxAdapter(
                child: _buildOrderSection(context, isLoggedIn),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: AppDimens.spacingM),
              ),
              // 功能列表
              SliverToBoxAdapter(
                child: _buildFunctionList(context, isLoggedIn),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: AppDimens.spacingM),
              ),
              // 退出登录（已登录状态显示）
              if (isLoggedIn)
                SliverToBoxAdapter(
                  child: _buildLogoutButton(context),
                ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 40),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    bool isLoggedIn,
    dynamic user,
  ) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppDimens.spacingL,
        AppDimens.spacingXL + MediaQuery.of(context).padding.top,
        AppDimens.spacingL,
        AppDimens.spacingXL,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, Color(0xFFFF8C42)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: InkWell(
        onTap: () {
          if (!isLoggedIn) {
            context.push('/login');
          }
        },
        child: Row(
          children: [
            // 头像
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                color: Colors.white24,
              ),
              child: ClipOval(
                child: isLoggedIn && user?.avatar != null && user.avatar.isNotEmpty
                    ? Image.network(
                        user.avatar,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.person, color: Colors.white, size: 32),
                      )
                    : const Icon(Icons.person, color: Colors.white, size: 32),
              ),
            ),
            const SizedBox(width: AppDimens.spacingM),
            // 用户信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isLoggedIn ? (user?.nickname ?? '用户') : '点击登录',
                    style: const TextStyle(
                      fontSize: AppDimens.fontL,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (isLoggedIn)
                    Text(
                      user?.phone != null
                          ? _maskPhone(user!.phone)
                          : '',
                      style: const TextStyle(
                        fontSize: AppDimens.fontS,
                        color: Colors.white70,
                      ),
                    )
                  else
                    const Text(
                      '登录后享受更多优惠',
                      style: TextStyle(
                        fontSize: AppDimens.fontS,
                        color: Colors.white70,
                      ),
                    ),
                ],
              ),
            ),
            if (!isLoggedIn)
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.white70,
              ),
          ],
        ),
      ),
    );
  }

  String _maskPhone(String phone) {
    if (phone.length < 7) return phone;
    return phone.replaceRange(3, 7, '****');
  }

  Widget _buildOrderSection(BuildContext context, bool isLoggedIn) {
    final orderItems = [
      _OrderItem(icon: Icons.payment_outlined, label: '待付款', count: 0, status: 0),
      _OrderItem(icon: Icons.inventory_2_outlined, label: '待发货', count: 0, status: 1),
      _OrderItem(icon: Icons.local_shipping_outlined, label: '待收货', count: 0, status: 2),
      _OrderItem(icon: Icons.reviews_outlined, label: '待评价', count: 0, status: 3),
      _OrderItem(icon: Icons.refresh_outlined, label: '退换/售后', count: 0, status: 3),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.spacingL,
        AppDimens.spacingS,
        AppDimens.spacingL,
        0,
      ),
      child: Container(
          padding: const EdgeInsets.all(AppDimens.spacingM),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppDimens.radiusM),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // 标题行
              Row(
                children: [
                  const Text(
                    '我的订单',
                    style: TextStyle(
                      fontSize: AppDimens.fontM,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () {
                      if (isLoggedIn) {
                        context.push('/orders');
                      } else {
                        context.push('/login');
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          '全部订单',
                          style: TextStyle(
                            fontSize: AppDimens.fontS,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: AppColors.textHint,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.spacingM),
              // 订单快捷入口
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: orderItems
                    .map((item) => _buildOrderItem(context, item, isLoggedIn))
                    .toList(),
              ),
            ],
          ),
        ),
      );
  }

  Widget _buildOrderItem(
    BuildContext context,
    _OrderItem item,
    bool isLoggedIn,
  ) {
    return InkWell(
      onTap: () {
        if (!isLoggedIn) {
          context.push('/login');
          return;
        }
        context.push('/orders?status=${item.status}');
      },
      borderRadius: BorderRadius.circular(AppDimens.radiusS),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                item.icon,
                size: 26,
                color: AppColors.textSecondary,
              ),
              if (item.count > 0)
                Positioned(
                  right: -8,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    constraints: const BoxConstraints(minWidth: 16),
                    decoration: BoxDecoration(
                      color: AppColors.price,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      item.count > 99 ? '99+' : '${item.count}',
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
          ),
          const SizedBox(height: 6),
          Text(
            item.label,
            style: const TextStyle(
              fontSize: AppDimens.fontXS,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFunctionList(BuildContext context, bool isLoggedIn) {
    final functionItems = [
      _FunctionItem(icon: Icons.favorite_border, label: '我的收藏'),
      _FunctionItem(icon: Icons.history, label: '浏览记录'),
      _FunctionItem(icon: Icons.location_on_outlined, label: '收货地址'),
      _FunctionItem(icon: Icons.account_balance_wallet_outlined, label: '我的钱包'),
      _FunctionItem(icon: Icons.card_giftcard, label: '优惠券'),
      _FunctionItem(icon: Icons.star_border, label: '我的积分'),
      _FunctionItem(icon: Icons.help_outline, label: '帮助中心'),
      _FunctionItem(icon: Icons.settings_outlined, label: '设置'),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimens.spacingL),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
      ),
      child: Column(
        children: functionItems.asMap().entries.map((entry) {
          final item = entry.value;
          final isLast = entry.key == functionItems.length - 1;
          return InkWell(
            onTap: () {
              if (item.label == '设置') {
                context.push('/settings');
                return;
              }
              if (!isLoggedIn) {
                context.push('/login');
                return;
              }
              // 其他功能先占位
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${item.label}功能开发中'),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimens.radiusM),
                  ),
                  margin: const EdgeInsets.all(AppDimens.spacingL),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.spacingL,
                vertical: AppDimens.spacingM,
              ),
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : const Border(
                        bottom: BorderSide(
                          color: AppColors.divider,
                          width: 0.5,
                        ),
                      ),
              ),
              child: Row(
                children: [
                  Icon(
                    item.icon,
                    size: 22,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppDimens.spacingM),
                  Expanded(
                    child: Text(
                      item.label,
                      style: const TextStyle(
                        fontSize: AppDimens.fontM,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: AppColors.textHint,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimens.spacingL),
      child: SizedBox(
        width: double.infinity,
        height: AppDimens.buttonHeight,
        child: OutlinedButton(
          onPressed: () {
            _showLogoutDialog(context);
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            side: const BorderSide(color: AppColors.divider),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusM),
            ),
          ),
          child: const Text('退出登录'),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('提示'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<AuthBloc>().add(const AuthLoggedOut());
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

class _OrderItem {
  final IconData icon;
  final String label;
  final int count;
  final int status;

  const _OrderItem({
    required this.icon,
    required this.label,
    required this.count,
    required this.status,
  });
}

class _FunctionItem {
  final IconData icon;
  final String label;

  const _FunctionItem({
    required this.icon,
    required this.label,
  });
}
