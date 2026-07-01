import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/onboarding_model.dart';

/// A single full-screen onboarding slide.
///
/// Layout:
///   • Full-screen rice image (background)
///   • Multi-stop dark gradient bottom overlay (readability)
///   • Brand badge + title + subtitle pinned at `bottom: 240`
///     — this keeps text well above the page indicator + CTA button
///     area (which reaches up to ~200 px from bottom on the last slide)
class OnboardingSlide extends StatelessWidget {
  const OnboardingSlide({super.key, required this.model});

  final OnboardingModel model;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Background image ───────────────────────────────────────
        _SlideBackground(model: model),

        // ── Gradient — makes lower portion dark for text legibility
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.30, 0.60, 1.0],
              colors: [
                Colors.transparent,
                Color(0x99000000),
                Color(0xEE000000),
              ],
            ),
          ),
        ),

        // ── Text content — pinned above the overlay using a screen-height fraction
        Positioned(
          left: 24,
          right: 24,
          bottom: MediaQuery.of(context).size.height * 0.30,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Brand badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🌾', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      'World of Rice',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                model.title,
                style: GoogleFonts.poppins(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                model.subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withValues(alpha: 0.85),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Background ────────────────────────────────────────────────────────────────

class _SlideBackground extends StatelessWidget {
  const _SlideBackground({required this.model});

  final OnboardingModel model;

  @override
  Widget build(BuildContext context) {
    if (model.imagePath != null) {
      final path = model.imagePath!;
      final isNetwork = path.startsWith('http');
      return isNetwork
          ? Image.network(
              path,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _GradientBg(color: model.bgColor),
            )
          : Image.asset(
              path,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _GradientBg(color: model.bgColor),
            );
    }
    return _GradientBg(color: model.bgColor);
  }
}

class _GradientBg extends StatelessWidget {
  const _GradientBg({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, Colors.black, 0.45)!],
        ),
      ),
    );
  }
}
