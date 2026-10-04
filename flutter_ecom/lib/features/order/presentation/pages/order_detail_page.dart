import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/extensions/num_extensions.dart';
import '../../../../core/widgets/common/cache_network_image.dart';
import '../../../../core/widgets/common/loading_indicator.dart';
import '../../domain/entities/order_entity.dart';
import '../bloc/order_detail_bloc.dart';
import '../bloc/order_detail_event.dart';
import '../bloc/order_detail_state.dart';
import '../widgets/logistics_timeline.dart';
import '../widgets/order_status_tag.dart';

/// 订单详情页
///
/// 面试讲解点：
/// 订单详情页使用 CustomScrollView + 多个卡片区域，
/// 顶部展示状态横幅，中间依次是地址、物流、商品、订单信息、费用明细，
/// 底部是固定操作栏。
///
/// 各区域根据订单状态条件渲染（如物流信息仅待收货状态有）。
class OrderDetailPage extends StatefulWidget {
  const OrderDetailPage({super.key, required this.orderId});

  final String orderId;

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  late final OrderDetailBloc _orderDetailBloc;

  @override
  void initState() {
    super.initState();
    // 在 initState 中创建 Bloc 实例，避免每次 build 都创建新实例
    _orderDetailBloc = getIt<OrderDetailBloc>()
      ..add(OrderDetailStarted(widget.orderId));
  }

  @override
  void dispose() {
    _orderDetailBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _orderDetailBloc,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('订单详情'),
          backgroundColor: AppColors.white,
          elevation: 0.5,
        ),
        body: BlocBuilder<OrderDetailBloc, OrderDetailState>(
          builder: (context, state) {
            if (state is OrderDetailLoading) {
              return const LoadingIndicator();
            }
            if (state is OrderDetailFailure) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 64, color: AppColors.error),
                    const SizedBox(height: AppDimens.spacingM),
                    Text(
                      state.message,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppDimens.spacingL),
                    ElevatedButton(
                      onPressed: () {
                        context
                            .read<OrderDetailBloc>()
                            .add(OrderDetailStarted(widget.orderId));
                      },
                      child: const Text('重新加载'),
                    ),
                  ],
                ),
              );
            }
            OrderEntity order;
            bool isActionLoading = false;
            if (state is OrderDetailSuccess) {
              order = state.order;
            } else if (state is OrderDetailActionLoading) {
              order = state.order;
              isActionLoading = true;
            } else {
              return const SizedBox.shrink();
            }
            return _buildContent(context, order, isActionLoading);
          },
        ),
        bottomNavigationBar:
            BlocBuilder<OrderDetailBloc, OrderDetailState>(
          builder: (context, state) {
            if (state is OrderDetailSuccess) {
              return _buildBottomBar(context, state.order, false);
            }
            if (state is OrderDetailActionLoading) {
              return _buildBottomBar(context, state.order, true);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    OrderEntity order,
    bool isActionLoading,
  ) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              // 顶部状态横幅
              _buildStatusHeader(order),
              const SizedBox(height: AppDimens.spacingS),
              // 收货地址
              _buildAddressCard(order),
              const SizedBox(height: AppDimens.spacingS),
              // 物流信息（待收货状态才显示）
              if (order.logistics != null) _buildLogisticsCard(order),
              if (order.logistics != null)
                const SizedBox(height: AppDimens.spacingS),
              // 商品列表
              _buildProductList(order),
              const SizedBox(height: AppDimens.spacingS),
              // 订单信息
              _buildOrderInfo(order),
              const SizedBox(height: AppDimens.spacingS),
              // 费用明细
              _buildFeeDetail(order),
              const SizedBox(height: 80), // 底部占位
            ],
          ),
        ),
      ],
    );
  }

  // 顶部状态横幅
  Widget _buildStatusHeader(OrderEntity order) {
    Color bgColor;
    String iconPath;
    switch (order.orderStatus) {
      case OrderStatus.pendingPayment:
        bgColor = AppColors.price;
        iconPath = '待支付';
        break;
      case OrderStatus.pendingShipment:
        bgColor = AppColors.warning;
        iconPath = '待发货';
        break;
      case OrderStatus.pendingReceipt:
        bgColor = AppColors.primary;
        iconPath = '待收货';
        break;
      case OrderStatus.completed:
        bgColor = AppColors.success;
        iconPath = '已完成';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.spacingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bgColor, bgColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            order.statusText,
            style: const TextStyle(
              fontSize: AppDimens.fontXL,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _getStatusSubtitle(order),
            style: TextStyle(
              fontSize: AppDimens.fontS,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusSubtitle(OrderEntity order) {
    switch (order.orderStatus) {
      case OrderStatus.pendingPayment:
        return '请在30分钟内完成支付';
      case OrderStatus.pendingShipment:
        return '商家正在准备发货，请耐心等待';
      case OrderStatus.pendingReceipt:
        return '商品已发出，请注意查收';
      case OrderStatus.completed:
        return '感谢您的购买，欢迎再次光临';
    }
  }

  // 收货地址卡片
  Widget _buildAddressCard(OrderEntity order) {
    return Container(
      width: double.infinity,
      color: AppColors.white,
      padding: const EdgeInsets.all(AppDimens.spacingM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.location_on_outlined,
              size: 20, color: AppColors.primary),
          const SizedBox(width: AppDimens.spacingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      order.address.name,
                      style: const TextStyle(
                        fontSize: AppDimens.fontM,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: AppDimens.spacingM),
                    Text(
                      order.address.phone,
                      style: const TextStyle(
                        fontSize: AppDimens.fontS,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  order.address.fullAddress,
                  style: const TextStyle(
                    fontSize: AppDimens.fontS,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios,
              size: 14, color: AppColors.textHint),
        ],
      ),
    );
  }

  // 物流卡片
  Widget _buildLogisticsCard(OrderEntity order) {
    final logistics = order.logistics!;
    return Container(
      width: double.infinity,
      color: AppColors.white,
      padding: const EdgeInsets.all(AppDimens.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_shipping_outlined,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                logistics.company,
                style: const TextStyle(
                  fontSize: AppDimens.fontS,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: AppDimens.spacingS),
              Text(
                '运单号：${logistics.trackingNo}',
                style: const TextStyle(
                  fontSize: AppDimens.fontXS,
                  color: AppColors.textHint,
                ),
              ),
              const Spacer(),
              const Text(
                '查看物流',
                style: TextStyle(
                  fontSize: AppDimens.fontXS,
                  color: AppColors.textHint,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_ios,
                  size: 12, color: AppColors.textHint),
            ],
          ),
          const SizedBox(height: AppDimens.spacingM),
          LogisticsTimeline(updates: logistics.updates),
        ],
      ),
    );
  }

  // 商品列表
  Widget _buildProductList(OrderEntity order) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.all(AppDimens.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '商品信息',
            style: TextStyle(
              fontSize: AppDimens.fontM,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimens.spacingM),
          ...order.items.asMap().entries.map((entry) {
            final item = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                bottom: entry.key == order.items.length - 1
                    ? 0
                    : AppDimens.spacingM,
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppDimens.radiusS),
                    child: AppNetworkImage(
                      imageUrl: item.imageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: AppDimens.spacingM),
                  Expanded(
                    child: SizedBox(
                      height: 80,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item.productName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: AppDimens.fontS,
                              color: AppColors.textPrimary,
                              height: 1.3,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                item.specs,
                                style: const TextStyle(
                                  fontSize: AppDimens.fontXS,
                                  color: AppColors.textHint,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                item.price.toPriceString(),
                                style: const TextStyle(
                                  fontSize: AppDimens.fontS,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                ' x${item.quantity}',
                                style: const TextStyle(
                                  fontSize: AppDimens.fontXS,
                                  color: AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // 订单信息
  Widget _buildOrderInfo(OrderEntity order) {
    return Container(
      width: double.infinity,
      color: AppColors.white,
      padding: const EdgeInsets.all(AppDimens.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '订单信息',
            style: TextStyle(
              fontSize: AppDimens.fontM,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimens.spacingM),
          _buildInfoRow('订单编号', order.orderNo),
          const SizedBox(height: AppDimens.spacingS),
          _buildInfoRow('下单时间', order.createTime),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: AppDimens.fontS,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: AppDimens.fontS,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // 费用明细
  Widget _buildFeeDetail(OrderEntity order) {
    return Container(
      width: double.infinity,
      color: AppColors.white,
      padding: const EdgeInsets.all(AppDimens.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '费用明细',
            style: TextStyle(
              fontSize: AppDimens.fontM,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimens.spacingM),
          _buildInfoRow('商品总额', order.totalAmount.toPriceString()),
          const SizedBox(height: AppDimens.spacingS),
          _buildInfoRow('运费', order.freight.toPriceString()),
          const SizedBox(height: AppDimens.spacingS),
          _buildInfoRow(
            '优惠',
            '-${order.discount.toPriceString()}',
          ),
          const SizedBox(height: AppDimens.spacingS),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: AppDimens.spacingS),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text(
                '实付款 ',
                style: TextStyle(
                  fontSize: AppDimens.fontS,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                order.payAmount.toPriceString(),
                style: const TextStyle(
                  fontSize: AppDimens.fontM,
                  fontWeight: FontWeight.bold,
                  color: AppColors.price,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 底部操作栏
  Widget _buildBottomBar(
    BuildContext context,
    OrderEntity order,
    bool isActionLoading,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.spacingM,
        vertical: AppDimens.spacingS,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: _buildBottomButtons(context, order, isActionLoading),
        ),
      ),
    );
  }

  List<Widget> _buildBottomButtons(
    BuildContext context,
    OrderEntity order,
    bool isLoading,
  ) {
    switch (order.orderStatus) {
      case OrderStatus.pendingPayment:
        return [
          _buildOutlineBtn('取消订单', isLoading, () {
            context.read<OrderDetailBloc>().add(
                  const OrderDetailCancelled(),
                );
          }),
          const SizedBox(width: AppDimens.spacingS),
          _buildPrimaryBtn('立即支付', isLoading, () {}),
        ];
      case OrderStatus.pendingShipment:
        return [
          _buildOutlineBtn('取消订单', isLoading, () {
            context.read<OrderDetailBloc>().add(
                  const OrderDetailCancelled(),
                );
          }),
          const SizedBox(width: AppDimens.spacingS),
          _buildOutlineBtn('提醒发货', isLoading, () {}),
        ];
      case OrderStatus.pendingReceipt:
        return [
          _buildOutlineBtn('查看物流', isLoading, () {}),
          const SizedBox(width: AppDimens.spacingS),
          _buildPrimaryBtn('确认收货', isLoading, () {
            context.read<OrderDetailBloc>().add(
                  const OrderDetailConfirmed(),
                );
          }),
        ];
      case OrderStatus.completed:
        return [
          _buildOutlineBtn('申请售后', isLoading, () {}),
          const SizedBox(width: AppDimens.spacingS),
          _buildOutlineBtn('再次购买', isLoading, () {}),
        ];
    }
  }

  Widget _buildOutlineBtn(
    String text,
    bool isLoading,
    VoidCallback onTap,
  ) {
    return OutlinedButton(
      onPressed: isLoading ? null : onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.spacingL,
          vertical: 10,
        ),
        side: const BorderSide(color: AppColors.divider),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusFull),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: AppDimens.fontS,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildPrimaryBtn(
    String text,
    bool isLoading,
    VoidCallback onTap,
  ) {
    return ElevatedButton(
      onPressed: isLoading ? null : onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.price,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.spacingL,
          vertical: 10,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusFull),
        ),
        elevation: 0,
      ),
      child: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(
              text,
              style: const TextStyle(
                fontSize: AppDimens.fontS,
                fontWeight: FontWeight.w500,
              ),
            ),
    );
  }
}
