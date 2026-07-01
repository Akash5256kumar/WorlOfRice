import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

/// Displays the circular JOY World of Rice logo badge.
///
/// Falls back to a branded placeholder if the asset isn't present yet.
/// Usage:
/// ```dart
/// AppLogo(size: AppDimensions.logoSize)
/// ```
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = AppDimensions.logoSize,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        AppAssets.logo,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            _LogoPlaceholder(size: size),
      ),
    );
  }
}

// ── Private fallback ─────────────────────────────────────────────────────────

class _LogoPlaceholder extends StatelessWidget {
  const _LogoPlaceholder({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.darkBrown,
      ),
      alignment: Alignment.center,
      child: Text(
        'JOY',
        style: TextStyle(
          color: AppColors.accentGold,
          fontSize: size * 0.22,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
