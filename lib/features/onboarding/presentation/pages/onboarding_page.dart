import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/routes/app_routes.dart';
import '../../data/models/onboarding_model.dart';
import '../bloc/onboarding_bloc.dart';
import '../widgets/onboarding_slide.dart';
import '../widgets/page_indicator.dart';

/// The onboarding carousel.
///
/// React behaviour:
/// - Non-last slides: "Get Started" advances to the next slide.
/// - Last slide: shows "Sign Up" (primary) + "Login" (outlined) CTAs that
///   navigate directly to the auth screen.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  late final PageController _pageController;

  static const List<OnboardingModel> _slides = [
    OnboardingModel(
      title: AppStrings.onboardingSlide1Title,
      subtitle: AppStrings.onboardingSlide1Subtitle,
      imagePath: AppAssets.onboardScreen1,
      bgColor: Color(0xFF1A5C38),
    ),
    OnboardingModel(
      title: AppStrings.onboardingSlide2Title,
      subtitle: AppStrings.onboardingSlide2Subtitle,
      imagePath: AppAssets.onboardScreen2,
      bgColor: Color(0xFF2C1F0E),
    ),
    OnboardingModel(
      title: AppStrings.onboardingSlide3Title,
      subtitle: AppStrings.onboardingSlide3Subtitle,
      imagePath: AppAssets.onboardScreen3,
      bgColor: Color(0xFF0D3D24),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _advance() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OnboardingBloc(totalPages: _slides.length),
      child: Scaffold(
        backgroundColor: AppColors.onboardingGradientBottom,
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            _OnboardingPageView(
              controller: _pageController,
              slides: _slides,
            ),
            _OnboardingOverlay(
              controller: _pageController,
              slidesCount: _slides.length,
              onAdvance: _advance,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Private sub-widgets ──────────────────────────────────────────────────────

class _OnboardingPageView extends StatelessWidget {
  const _OnboardingPageView({
    required this.controller,
    required this.slides,
  });

  final PageController controller;
  final List<OnboardingModel> slides;

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: controller,
      itemCount: slides.length,
      onPageChanged: (index) => context
          .read<OnboardingBloc>()
          .add(OnboardingPageChanged(pageIndex: index)),
      itemBuilder: (_, index) => OnboardingSlide(model: slides[index]),
    );
  }
}

class _OnboardingOverlay extends StatelessWidget {
  const _OnboardingOverlay({
    required this.controller,
    required this.slidesCount,
    required this.onAdvance,
  });

  final PageController controller;
  final int slidesCount;
  final VoidCallback onAdvance;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingBloc, OnboardingState>(
      builder: (context, state) {
        final isLastPage = state is OnboardingInProgress && state.isLastPage;

        final bottomInset = MediaQuery.of(context).padding.bottom;
        return Positioned(
          left: AppDimensions.spaceXXL,
          right: AppDimensions.spaceXXL,
          bottom: bottomInset + AppDimensions.spaceL,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              OnboardingPageIndicator(
                controller: controller,
                count: slidesCount,
              ),
              const SizedBox(height: 20),
              if (isLastPage)
                _LastSlideButtons()
              else
                _GetStartedButton(onTap: onAdvance),
            ],
          ),
        );
      },
    );
  }
}

/// Non-last slide: single "Get Started →" button that advances the carousel.
class _GetStartedButton extends StatelessWidget {
  const _GetStartedButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDimensions.buttonHeight,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: AppColors.textWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
          ),
          elevation: AppDimensions.elevationNone,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppStrings.getStarted,
              style: GoogleFonts.poppins(
                fontSize: AppDimensions.fontSizeL,
                fontWeight: FontWeight.w600,
                color: AppColors.textWhite,
              ),
            ),
            const SizedBox(width: AppDimensions.spaceS),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textWhite,
              size: AppDimensions.iconSizeL,
            ),
          ],
        ),
      ),
    );
  }
}

/// Last slide: "Sign Up" (primary green) + "Login" (outlined white).
/// Matches React's final onboarding slide layout.
class _LastSlideButtons extends StatelessWidget {
  const _LastSlideButtons();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Sign Up — primary
        SizedBox(
          height: AppDimensions.buttonHeight,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => context.go(
              AppRoutes.auth,
              extra: <String, dynamic>{'tab': 1},
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              foregroundColor: AppColors.textWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
              ),
              elevation: AppDimensions.elevationNone,
            ),
            child: Text(
              AppStrings.signUp,
              style: GoogleFonts.poppins(
                fontSize: AppDimensions.fontSizeL,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.spaceM),
        // Login — outlined white
        SizedBox(
          height: AppDimensions.buttonHeight,
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => context.go(
              AppRoutes.auth,
              extra: <String, dynamic>{'tab': 0},
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textWhite,
              side: const BorderSide(
                color: AppColors.textWhite,
                width: AppDimensions.borderWidthMedium,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
              ),
            ),
            child: Text(
              AppStrings.login,
              style: GoogleFonts.poppins(
                fontSize: AppDimensions.fontSizeL,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
