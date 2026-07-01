import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

/// Animated dot page indicator for the onboarding carousel.
///
/// Uses [SmoothPageIndicator] with a WormEffect for the active dot.
class OnboardingPageIndicator extends StatelessWidget {
  const OnboardingPageIndicator({
    super.key,
    required this.controller,
    required this.count,
  });

  final PageController controller;
  final int count;

  @override
  Widget build(BuildContext context) {
    // React: inactive w-2 h-2 bg-white/40, active w-8 h-2 bg-[#D4A017]
    // WormEffect stretches the active dot to ~32px matching React's w-8.
    return SmoothPageIndicator(
      controller: controller,
      count: count,
      effect: WormEffect(
        activeDotColor: AppColors.accentGold,
        dotColor: Colors.white.withValues(alpha: 0.40),
        dotHeight: AppDimensions.indicatorDotHeight,
        dotWidth: AppDimensions.indicatorDotWidth,
        spacing: AppDimensions.indicatorDotSpacing,
        strokeWidth: 0,
      ),
    );
  }
}
