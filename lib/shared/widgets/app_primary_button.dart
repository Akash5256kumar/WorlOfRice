import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

/// A branded full-width primary green button with optional loading state.
///
/// Usage:
/// ```dart
/// AppPrimaryButton(
///   label: AppStrings.loginButton,
///   onPressed: _onLogin,
///   isLoading: state.isLoading,
/// )
/// ```
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.height,
    this.borderRadius,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Widget? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? AppColors.primaryGreen;
    final fgColor = foregroundColor ?? AppColors.textWhite;
    final br = borderRadius ??
        BorderRadius.circular(AppDimensions.radiusL);

    return SizedBox(
      height: height ?? AppDimensions.buttonHeight,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          disabledBackgroundColor: bgColor.withValues(alpha: 0.7),
          shape: RoundedRectangleBorder(borderRadius: br),
          elevation: AppDimensions.elevationNone,
        ),
        child: isLoading
            ? const _LoadingIndicator()
            : _ButtonContent(label: label, icon: icon),
      ),
    );
  }
}

// ── Private sub-widgets ──────────────────────────────────────────────────────

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({required this.label, this.icon});

  final String label;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon!,
          const SizedBox(width: AppDimensions.spaceS),
          Text(label),
        ],
      );
    }
    return Text(label);
  }
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: AppDimensions.iconSizeL,
      width: AppDimensions.iconSizeL,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.textWhite),
      ),
    );
  }
}
