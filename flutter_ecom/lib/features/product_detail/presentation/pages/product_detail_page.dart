import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/widgets/common/loading_indicator.dart';
import '../../../../core/widgets/common/error_state.dart';
import '../../../cart/domain/entities/cart_item_entity.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../cart/presentation/bloc/cart_event.dart';
import '../bloc/product_detail_bloc.dart';
import '../bloc/product_detail_event.dart';
import '../bloc/product_detail_state.dart';
import '../widgets/product_image_gallery.dart';
import '../widgets/product_info_panel.dart';
import '../widgets/product_spec_bar.dart';
import '../widgets/product_service_bar.dart';
import '../widgets/product_bottom_bar.dart';
import '../widgets/product_spec_sheet.dart';

/// 商品详情页
///
/// 面试讲解点：
/// 使用 SliverAppBar 实现沉浸式滑动效果：
/// - 顶部是商品大图，AppBar 透明
/// - 向下滚动时，标题渐显，AppBar 变成不透明
///
/// 底部操作栏使用 Scaffold.bottomNavigationBar 固定在底部，
/// CustomScrollView 内部有 bottomBar 高度的占位，避免内容被遮挡。
class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({super.key, required this.productId});

  final int productId;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final ScrollController _scrollController = ScrollController();
  double _titleOpacity = 0.0;
  late final ProductDetailBloc _productBloc;

  @override
  void initState() {
    super.initState();
    // 面试讲解点：
    // Bloc 在 initState 中创建并发起加载请求，
    // 而不是在 build 方法里创建。因为 build 会被多次调用（比如 setState 滚动时），
    // 如果在 build 里调用 getIt（工厂模式），每次都会创建新的 Bloc 实例，
    // 导致重复请求和页面闪烁。
    // 在 initState 里创建一次，通过 BlocProvider.value 提供给子树，
    // 保证整个页面生命周期内只有一个 Bloc 实例。
    _productBloc = getIt<ProductDetailBloc>()
      ..add(ProductDetailLoadEvent(widget.productId));
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _productBloc.close();
    super.dispose();
  }

  void _onScroll() {
    // 滚动距离 0~200 时，标题透明度 0→1
    const double fadeStart = 0;
    const double fadeEnd = 200;
    final offset = _scrollController.offset;
    double opacity = 0.0;
    if (offset <= fadeStart) {
      opacity = 0.0;
    } else if (offset >= fadeEnd) {
      opacity = 1.0;
    } else {
      opacity = (offset - fadeStart) / (fadeEnd - fadeStart);
    }
    if (opacity != _titleOpacity) {
      setState(() {
        _titleOpacity = opacity;
      });
    }
  }

  void _showSpecSheet(BuildContext context, ProductDetailSuccess state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return ProductSpecSheet(
          product: state.product,
          onConfirm: (selectedSpecs, quantity) {
            _addToCart(state, selectedSpecs, quantity);
          },
        );
      },
    );
  }

  void _addToCart(
    ProductDetailSuccess state,
    Map<String, String> selectedSpecs,
    int quantity,
  ) {
    final specsText = selectedSpecs.values.where((v) => v.isNotEmpty).join(' ');
    final item = CartItemEntity(
      productId: state.product.id,
      productName: state.product.name,
      price: state.product.price,
      imageUrl: state.product.imageUrl,
      quantity: quantity,
      specs: specsText,
    );
    getIt<CartBloc>().add(CartItemAdded(item));

    // 提示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已加入购物车 x$quantity'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusM),
        ),
        margin: const EdgeInsets.all(AppDimens.spacingL),
      ),
    );
  }

  void _onBuyNow(ProductDetailSuccess state) {
    // 立即购买：先弹规格选择
    _showSpecSheet(context, state);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _productBloc,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: BlocBuilder<ProductDetailBloc, ProductDetailState>(
          builder: (context, state) {
            if (state is ProductDetailLoading) {
              return const LoadingIndicator();
            }
            if (state is ProductDetailFailure) {
              return ErrorState(
                message: state.message,
                onRetry: () => context
                    .read<ProductDetailBloc>()
                    .add(ProductDetailLoadEvent(widget.productId)),
              );
            }
            if (state is ProductDetailSuccess) {
              return _buildSuccessView(context, state);
            }
            return const SizedBox.shrink();
          },
        ),
        bottomNavigationBar:
            BlocBuilder<ProductDetailBloc, ProductDetailState>(
          builder: (context, state) {
            if (state is! ProductDetailSuccess) {
              return const SizedBox.shrink();
            }
            return ProductBottomBar(
              onAddToCart: () => _showSpecSheet(context, state),
              onBuyNow: () => _onBuyNow(state),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSuccessView(
    BuildContext context,
    ProductDetailSuccess state,
  ) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // SliverAppBar - 透明背景，滚动时标题渐显
        SliverAppBar(
          pinned: true,
          expandedHeight: 375,
          backgroundColor: AppColors.white,
          elevation: 0,
          scrolledUnderElevation: 0.5,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(_titleOpacity == 0 ? 0.3 : 0),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                size: 18,
                color: _titleOpacity == 0
                    ? Colors.white
                    : AppColors.textPrimary,
              ),
            ),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          actions: [
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(_titleOpacity == 0 ? 0.3 : 0),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.share_outlined,
                  size: 20,
                  color: _titleOpacity == 0
                      ? Colors.white
                      : AppColors.textPrimary,
                ),
              ),
              onPressed: () {},
            ),
          ],
          title: Opacity(
            opacity: _titleOpacity,
            child: Text(
              state.product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: AppDimens.fontL,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background:
                ProductImageGallery(images: state.product.images),
          ),
        ),
        // 商品信息
        SliverToBoxAdapter(
          child: Column(
            children: [
              ProductInfoPanel(product: state.product),
              const SizedBox(height: 8),
              ProductSpecBar(
                selectedSpecs: _getSelectedSpecsText(state),
                onTap: () => _showSpecSheet(context, state),
              ),
              const SizedBox(height: 8),
              ProductServiceBar(
                services: state.product.service,
                shipping: state.product.shipping,
              ),
              const SizedBox(height: 8),
              // 商品详情标题
              _buildSectionTitle('商品详情'),
              // 详情图文
              ...state.product.detailImages
                  .map((url) => Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimens.spacingL,
                          vertical: 4,
                        ),
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusS),
                          child: Image.network(
                            url,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ))
                  .toList(),
              const SizedBox(height: 8),
              // 商品描述
              _buildDescription(state.product.description),
              // 底部占位（避开 bottomBar）
              const SizedBox(height: AppDimens.bottomNavHeight + 20),
            ],
          ),
        ),
      ],
    );
  }

  String _getSelectedSpecsText(ProductDetailSuccess state) {
    if (state.product.specs.isEmpty) return '无规格';
    return state.product.specs
        .map((s) => s.values.isNotEmpty ? s.values.first : '')
        .where((v) => v.isNotEmpty)
        .join(' ');
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      width: double.infinity,
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.spacingL,
        vertical: AppDimens.spacingM,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: AppDimens.fontM,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildDescription(String description) {
    return Container(
      width: double.infinity,
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.spacingL,
        vertical: AppDimens.spacingM,
      ),
      child: Text(
        description,
        style: const TextStyle(
          fontSize: AppDimens.fontS,
          color: AppColors.textSecondary,
          height: 1.6,
        ),
      ),
    );
  }
}
