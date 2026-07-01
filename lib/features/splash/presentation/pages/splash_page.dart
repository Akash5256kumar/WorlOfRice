import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../shared/widgets/app_logo.dart';

/// Splash screen shown for 2.5 seconds on app launch.
///
/// Matches React's splash screen: dark-brown background, centred logo,
/// gold heritage tagline, then auto-navigates to onboarding.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    Future.delayed(const Duration(milliseconds: 2500), () async {
      if (!mounted) return;
      // ── Industry-standard persistent login check ───────────────────────────
      // If a JWT token is already stored from a previous session, skip
      // onboarding + login and go straight to Home.
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (!mounted) return;
      if (token != null && token.isNotEmpty) {
        context.go(AppRoutes.home);   // ✅ already logged in → Home
      } else {
        context.go(AppRoutes.onboarding); // first time / logged out → Onboarding
      }
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBrown,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Subtle diagonal-cross pattern overlay (10% opacity white)
          CustomPaint(painter: _CrossPatternPainter()),
          // Centred content with fade-in
          FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AppLogo(size: AppDimensions.logoSizeSplash),
                const SizedBox(height: AppDimensions.spaceXXL),
                Text(
                  AppStrings.appName.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: AppDimensions.fontSizeXXL,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textWhite,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceS),
                Text(
                  AppStrings.appSplashTagline,
                  style: GoogleFonts.poppins(
                    fontSize: AppDimensions.fontSizeM,
                    fontWeight: FontWeight.w400,
                    color: AppColors.accentGold.withValues(alpha: 0.85),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Paints a subtle repeating diagonal-cross grid at 10% white opacity —
/// matching the React splash screen pattern overlay.
class _CrossPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const step = 28.0;
    for (double x = 0; x < size.width + size.height; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(0, x), paint);
      canvas.drawLine(Offset(x, size.height), Offset(size.width, x - size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
