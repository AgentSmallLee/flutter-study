import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/widgets/common/cache_network_image.dart';

/// 商品图片轮播组件
class ProductImageGallery extends StatefulWidget {
  const ProductImageGallery({
    super.key,
    required this.images,
    this.height = 375,
  });

  final List<String> images;
  final double height;

  @override
  State<ProductImageGallery> createState() => _ProductImageGalleryState();
}

class _ProductImageGalleryState extends State<ProductImageGallery> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: const Center(child: Text('暂无图片')),
      );
    }

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        CarouselSlider.builder(
          options: CarouselOptions(
            height: widget.height,
            viewportFraction: 1.0,
            enlargeCenterPage: false,
            autoPlay: false,
            onPageChanged: (index, reason) {
              setState(() => _currentIndex = index);
            },
          ),
          itemCount: widget.images.length,
          itemBuilder: (context, index, realIndex) {
            return AppNetworkImage(
              imageUrl: widget.images[index],
              width: double.infinity,
              height: widget.height,
              fit: BoxFit.cover,
            );
          },
        ),
        // 指示器
        Positioned(
          bottom: AppDimens.spacingL,
          child: AnimatedSmoothIndicator(
            activeIndex: _currentIndex,
            count: widget.images.length,
            effect: const WormEffect(
              dotWidth: 6,
              dotHeight: 6,
              dotColor: Colors.white54,
              activeDotColor: Colors.white,
              strokeWidth: 0,
            ),
          ),
        ),
      ],
    );
  }
}
