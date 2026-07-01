import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

/// A reusable outlined (border-only) button, typically used on dark backgrounds.
///
/// Usage:
/// ```dart
/// AppOutlineButton(
///   label: AppStrings.login,
///   onPressed: _onLogin,
///   borderColor: AppColors.textWhite,
///   foregroundColor: AppColors.textWhite,
/// )
/// ```
class AppOutlineButton extends StatelessWidget {
  const AppOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.borderColor = AppColors.textWhite,
    this.foregroundColor = AppColors.textWhite,
    this.height,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color borderColor;
  final Color foregroundColor;
  final double? height;
  final Widget? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height ?? AppDimensions.buttonHeight,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: foregroundColor,
          side: BorderSide(
            color: borderColor,
            width: AppDimensions.borderWidthMedium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          ),
          elevation: AppDimensions.elevationNone,
        ),
        child: isLoading
            ? _LoadingIndicator(color: foregroundColor)
            : _ButtonContent(label: label, icon: icon, color: foregroundColor),
      ),
    );
  }
}

// ── Private sub-widgets ──────────────────────────────────────────────────────

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.label,
    required this.color,
    this.icon,
  });

  final String label;
  final Color color;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon!,
          const SizedBox(width: AppDimensions.spaceS),
          Text(label, style: TextStyle(color: color)),
        ],
      );
    }
    return Text(label, style: TextStyle(color: color));
  }
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDimensions.iconSizeL,
      width: AppDimensions.iconSizeL,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}
