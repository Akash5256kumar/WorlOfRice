import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../shared/widgets/app_outline_button.dart';
import '../../../../shared/widgets/app_primary_button.dart';

/// Full-screen Welcome / Landing page.
///
/// Shows a rice photography background with Sign Up and Login CTAs.
/// Navigates to [AppRoutes.auth] with the appropriate initial tab.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Restore system UI after immersive onboarding
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _WelcomeBackground(),
          const _WelcomeGradientOverlay(),
          _WelcomeContent(
            onSignUp: () => context.go(
              AppRoutes.auth,
              extra: <String, dynamic>{'tab': 1},
            ),
            onLogin: () => context.go(
              AppRoutes.auth,
              extra: <String, dynamic>{'tab': 0},
            ),
          ),
        ],
      ),
    );
  }
}

// ── Private sub-widgets ──────────────────────────────────────────────────────

class _WelcomeBackground extends StatelessWidget {
  const _WelcomeBackground();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppAssets.onboardScreen1,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.onboardingGradientTop,
              AppColors.onboardingGradientBottom,
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeGradientOverlay extends StatelessWidget {
  const _WelcomeGradientOverlay();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.4, 1.0],
          colors: [
            AppColors.transparent,
            AppColors.overlayDark.withValues(alpha: 0.2),
            AppColors.overlayDark.withValues(alpha: 0.88),
          ],
        ),
      ),
    );
  }
}

class _WelcomeContent extends StatelessWidget {
  const _WelcomeContent({
    required this.onSignUp,
    required this.onLogin,
  });

  final VoidCallback onSignUp;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final topPad = mq.padding.top + AppDimensions.spaceXXL;
    final bottomPad = mq.padding.bottom + AppDimensions.spaceXXL;

    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: mq.size.height),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppDimensions.spaceXXL,
            topPad,
            AppDimensions.spaceXXL,
            bottomPad,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _WelcomeTitleSection(),
              const SizedBox(height: AppDimensions.space40),
              AppPrimaryButton(
                label: AppStrings.signUp,
                onPressed: onSignUp,
              ),
              const SizedBox(height: AppDimensions.spaceL),
              AppOutlineButton(
                label: AppStrings.login,
                onPressed: onLogin,
                borderColor: AppColors.textWhite,
                foregroundColor: AppColors.textWhite,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeTitleSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.welcomeTitle,
          style: GoogleFonts.poppins(
            fontSize: AppDimensions.fontSizeHero,
            fontWeight: FontWeight.w800,
            color: AppColors.textWhite,
            height: AppDimensions.lineHeightTight,
          ),
        ),
        const SizedBox(height: AppDimensions.spaceS),
        Text(
          AppStrings.welcomeSubtitle,
          style: GoogleFonts.poppins(
            fontSize: AppDimensions.fontSizeL,
            fontWeight: FontWeight.w400,
            color: AppColors.textOnDark,
          ),
        ),
      ],
    );
  }
}
