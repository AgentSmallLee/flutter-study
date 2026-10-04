import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/widgets/common/cache_network_image.dart';
import '../../domain/entities/banner_entity.dart';

/// 首页 Banner 轮播组件
class HomeBanner extends StatefulWidget {
  const HomeBanner({super.key, required this.banners});

  final List<BannerEntity> banners;

  @override
  State<HomeBanner> createState() => _HomeBannerState();
}

class _HomeBannerState extends State<HomeBanner> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        CarouselSlider.builder(
          options: CarouselOptions(
            height: 160,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 3),
            autoPlayAnimationDuration: const Duration(milliseconds: 500),
            viewportFraction: 1.0,
            enlargeCenterPage: false,
            onPageChanged: (index, reason) {
              setState(() => _currentIndex = index);
            },
          ),
          itemCount: widget.banners.length,
          itemBuilder: (context, index, realIndex) {
            final banner = widget.banners[index];
            return _BannerItem(banner: banner);
          },
        ),
        const SizedBox(height: AppDimens.spacingS),
        // 指示器
        AnimatedSmoothIndicator(
          activeIndex: _currentIndex,
          count: widget.banners.length,
          effect: const WormEffect(
            dotWidth: 8,
            dotHeight: 8,
            dotColor: Colors.white54,
            activeDotColor: Colors.white,
            strokeWidth: 0,
          ),
        ),
        const SizedBox(height: AppDimens.spacingS),
      ],
    );
  }
}

class _BannerItem extends StatelessWidget {
  const _BannerItem({required this.banner});

  final BannerEntity banner;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.spacingL),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        child: AppNetworkImage(
          imageUrl: banner.imageUrl,
          width: double.infinity,
          height: 160,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
