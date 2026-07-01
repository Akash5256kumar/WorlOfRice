import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Data model for a single onboarding slide.
final class OnboardingModel extends Equatable {
  const OnboardingModel({
    required this.title,
    required this.subtitle,
    this.imagePath,
    this.bgColor = const Color(0xFF1A5C38),
  });

  /// Bold title displayed on the slide.
  final String title;

  /// Subtitle text beneath the title.
  final String subtitle;

  /// Network URL or local asset path for the background image.
  /// Falls back to a gradient using [bgColor] if null or on error.
  final String? imagePath;

  /// Fallback gradient base colour when [imagePath] is absent or fails.
  final Color bgColor;

  @override
  List<Object?> get props => [title, subtitle, imagePath, bgColor];
}
