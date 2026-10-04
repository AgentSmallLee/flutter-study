import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/extensions/num_extensions.dart';
import '../../../../core/widgets/common/cache_network_image.dart';
import '../../domain/entities/product_detail_entity.dart';

/// 规格选择 BottomSheet
///
/// 面试讲解点：
/// 使用 StatefulBuilder 是因为 showModalBottomSheet 内部的 setState 不会更新 UI，
/// StatefulBuilder 提供了独立的 StateSetter，可以在 BottomSheet 内更新状态。
class ProductSpecSheet extends StatefulWidget {
  const ProductSpecSheet({
    super.key,
    required this.product,
    this.initialQuantity = 1,
    required this.onConfirm,
  });

  final ProductDetailEntity product;
  final int initialQuantity;
  final void Function(Map<String, String> selectedSpecs, int quantity) onConfirm;

  @override
  State<ProductSpecSheet> createState() => _ProductSpecSheetState();
}

class _ProductSpecSheetState extends State<ProductSpecSheet> {
  late Map<String, String> _selectedSpecs;
  late int _quantity;

  @override
  void initState() {
    super.initState();
    // 默认选中每个规格组的第一个
    _selectedSpecs = {
      for (final spec in widget.product.specs)
        spec.name: spec.values.isNotEmpty ? spec.values.first : '',
    };
    _quantity = widget.initialQuantity;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimens.radiusL),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 顶部商品信息
          _buildHeader(),
          const Divider(height: 1),
          // 可滚动的规格选择区
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimens.spacingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 规格组
                  ...widget.product.specs
                      .map((spec) => _buildSpecGroup(spec.name, spec.values)),
                  const SizedBox(height: AppDimens.spacingL),
                  // 数量选择
                  _buildQuantitySelector(),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          // 底部确定按钮
          Padding(
            padding: EdgeInsets.all(AppDimens.spacingL).copyWith(
              bottom: AppDimens.spacingL +
                  MediaQuery.of(context).padding.bottom,
            ),
            child: SizedBox(
              width: double.infinity,
              height: AppDimens.buttonHeight,
              child: ElevatedButton(
                onPressed: () {
                  widget.onConfirm(_selectedSpecs, _quantity);
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppDimens.radiusFull),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  '确定',
                  style: TextStyle(
                    fontSize: AppDimens.fontL,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final selectedText = _selectedSpecs.values.where((v) => v.isNotEmpty).join(' ');
    return Padding(
      padding: const EdgeInsets.all(AppDimens.spacingL),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 商品缩略图
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimens.radiusS),
            child: AppNetworkImage(
              imageUrl: widget.product.imageUrl,
              width: 90,
              height: 90,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: AppDimens.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  widget.product.price.toPriceString(),
                  style: const TextStyle(
                    fontSize: AppDimens.fontXL,
                    fontWeight: FontWeight.bold,
                    color: AppColors.price,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  selectedText.isEmpty ? '请选择规格' : '已选 $selectedText',
                  style: const TextStyle(
                    fontSize: AppDimens.fontS,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // 关闭按钮
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(
              Icons.close,
              size: 20,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecGroup(String name, List<String> values) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontSize: AppDimens.fontM,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimens.spacingM),
          Wrap(
            spacing: AppDimens.spacingM,
            runSpacing: AppDimens.spacingS,
            children: values.map((value) {
              final isSelected = _selectedSpecs[name] == value;
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedSpecs[name] = value;
                  });
                },
                borderRadius: BorderRadius.circular(AppDimens.radiusS),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.spacingL,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryLight
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(AppDimens.radiusS),
                    border: Border.all(
                      color:
                          isSelected ? AppColors.primary : AppColors.divider,
                      width: isSelected ? 1.5 : 0.5,
                    ),
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: AppDimens.fontS,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          '数量',
          style: TextStyle(
            fontSize: AppDimens.fontM,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.divider),
            borderRadius: BorderRadius.circular(AppDimens.radiusS),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildQuantityButton(
                icon: Icons.remove,
                onTap: _quantity > 1
                    ? () => setState(() => _quantity--)
                    : null,
              ),
              Container(
                width: 40,
                alignment: Alignment.center,
                child: Text(
                  '$_quantity',
                  style: const TextStyle(
                    fontSize: AppDimens.fontM,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _buildQuantityButton(
                icon: Icons.add,
                onTap: _quantity < widget.product.stock
                    ? () => setState(() => _quantity++)
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 32,
        height: 32,
        child: Icon(
          icon,
          size: 18,
          color: onTap != null
              ? AppColors.textPrimary
              : AppColors.textHint,
        ),
      ),
    );
  }
}
