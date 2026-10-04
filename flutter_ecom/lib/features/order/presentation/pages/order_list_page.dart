import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/common/empty_state.dart';
import '../../../../core/widgets/common/error_state.dart';
import '../../../../core/widgets/common/loading_indicator.dart';
import '../bloc/order_list_bloc.dart';
import '../bloc/order_list_event.dart';
import '../bloc/order_list_state.dart';
import '../widgets/order_card.dart';

/// 订单列表页
///
/// 面试讲解点：
/// 使用 TabBar + TabBarView 实现状态筛选，5 个 Tab 共用同一个 Bloc，
/// 通过不同的 status 参数加载对应状态的订单。
///
/// 初始状态支持通过 query 参数传入（从个人中心订单入口跳转）。
class OrderListPage extends StatefulWidget {
  const OrderListPage({
    super.key,
    this.initialStatus,
  });

  /// 初始选中的状态（从个人中心跳转时传入）
  final int? initialStatus;

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // 5 个 Tab：全部 + 4 种状态
  static const List<_TabItem> _tabs = [
    _TabItem(label: '全部', status: null),
    _TabItem(label: '待付款', status: 0),
    _TabItem(label: '待发货', status: 1),
    _TabItem(label: '待收货', status: 2),
    _TabItem(label: '已完成', status: 3),
  ];

  late int _initIndex;
  late final OrderListBloc _orderListBloc;

  @override
  void initState() {
    super.initState();
    // 根据 initialStatus 找到对应的初始索引
    final initialIndex = _tabs.indexWhere(
      (t) => t.status == widget.initialStatus,
    );
    _initIndex = initialIndex >= 0 ? initialIndex : 0;
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: _initIndex,
    );
    // 在 initState 中创建 Bloc 实例，避免每次 build 都创建新实例
    _orderListBloc = getIt<OrderListBloc>()
      ..add(OrderListLoaded(status: _tabs[_initIndex].status));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _orderListBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _orderListBloc,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('我的订单'),
          backgroundColor: AppColors.white,
          elevation: 0.5,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(44),
            child: Container(
              color: AppColors.white,
              child: TabBar(
                controller: _tabController,
                onTap: (index) {
                  final status = _tabs[index].status;
                  _orderListBloc.add(OrderListLoaded(status: status));
                },
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(
                  fontSize: AppDimens.fontM,
                  fontWeight: FontWeight.w500,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: AppDimens.fontM,
                ),
                indicatorColor: AppColors.primary,
                indicatorSize: TabBarIndicatorSize.label,
                indicatorWeight: 2,
                tabs: _tabs
                    .map((e) => Tab(text: e.label))
                    .toList(),
              ),
            ),
          ),
        ),
        body: BlocBuilder<OrderListBloc, OrderListState>(
          builder: (context, state) {
            // 初次加载
            if (state.status == OrderListStatus.loading) {
              return const LoadingIndicator();
            }
            // 加载失败
            if (state.status == OrderListStatus.failure) {
              return ErrorState(
                message: state.errorMessage ?? '加载失败',
                onRetry: () {
                  _orderListBloc
                      .add(OrderListLoaded(status: state.currentStatus));
                },
              );
            }
            // 加载成功
            return EasyRefresh(
              onRefresh: () async {
                _orderListBloc.add(const OrderListRefreshed());
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(AppDimens.spacingM),
                itemCount: state.orders.length + 1,
                itemBuilder: (context, index) {
                  // 空状态
                  if (state.orders.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 100),
                      child: EmptyState(title: '暂无订单'),
                    );
                  }
                  // 加载更多 footer
                  if (index == state.orders.length) {
                    if (state.isLoadingMore) {
                      return const Padding(
                        padding: EdgeInsets.all(AppDimens.spacingL),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    }
                    if (!state.hasMore) {
                      return const Padding(
                        padding: EdgeInsets.all(AppDimens.spacingL),
                        child: Center(
                          child: Text(
                            '— 没有更多了 —',
                            style: TextStyle(color: AppColors.textHint),
                          ),
                        ),
                      );
                    }
                    // 触发加载更多
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _orderListBloc.add(const OrderListLoadMore());
                    });
                    return const SizedBox.shrink();
                  }
                  final order = state.orders[index];
                  return OrderCard(
                    order: order,
                    onCancel: () => _showCancelDialog(context, order.id),
                    onPay: () => _showToast(context, '去支付'),
                    onConfirm: () => _showConfirmDialog(context, order.id),
                    onViewLogistics: () {
                      context.push('/order/${order.id}');
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context, String orderId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('取消订单'),
        content: const Text('确定要取消该订单吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('再想想'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // 取消后刷新（Mock 环境模拟）
              _orderListBloc.add(const OrderListRefreshed());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('订单已取消')),
              );
            },
            child: const Text('确定取消'),
          ),
        ],
      ),
    );
  }

  void _showConfirmDialog(BuildContext context, String orderId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认收货'),
        content: const Text('确认已收到商品？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _orderListBloc.add(const OrderListRefreshed());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已确认收货')),
              );
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  void _showToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _TabItem {
  const _TabItem({required this.label, required this.status});

  final String label;
  final int? status;
}
