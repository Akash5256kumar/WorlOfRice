import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_dimensions.dart';

/// Complete centralized [ThemeData] for Joy World of Rice.
/// All widget themes are defined here — never override inline in widgets.
abstract final class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: _colorScheme,
        scaffoldBackgroundColor: AppColors.scaffoldBg,
        textTheme: _textTheme,
        inputDecorationTheme: _inputDecorationTheme,
        elevatedButtonTheme: _elevatedButtonTheme,
        outlinedButtonTheme: _outlinedButtonTheme,
        textButtonTheme: _textButtonTheme,
        tabBarTheme: _tabBarThemeData,
        dividerTheme: const DividerThemeData(
          color: AppColors.divider,
          thickness: AppDimensions.borderWidth,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.cardBg,
          elevation: AppDimensions.elevationNone,
          centerTitle: true,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: AppDimensions.fontSizeXL,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
        ),
      );

  // ── Color Scheme ───────────────────────────────────────────────────────
  static const ColorScheme _colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primaryGreen,
    onPrimary: AppColors.textWhite,
    primaryContainer: AppColors.primaryGreenLight,
    onPrimaryContainer: AppColors.textWhite,
    secondary: AppColors.accentGold,
    onSecondary: AppColors.darkBrown,
    secondaryContainer: AppColors.accentGoldLight,
    onSecondaryContainer: AppColors.darkBrown,
    surface: AppColors.cardBg,
    onSurface: AppColors.textPrimary,
    error: AppColors.error,
    onError: AppColors.textWhite,
  );

  // ── Text Theme ──────────────────────────────────────────────────────────
  static TextTheme get _textTheme => TextTheme(
        displayLarge: GoogleFonts.poppins(
          fontSize: AppDimensions.fontSizeHero,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          height: AppDimensions.lineHeightTight,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: AppDimensions.fontSizeDisplay,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          height: AppDimensions.lineHeightTight,
        ),
        headlineLarge: GoogleFonts.poppins(
          fontSize: AppDimensions.fontSizeXXL,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: AppDimensions.fontSizeXL,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: AppDimensions.fontSizeL,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: AppDimensions.fontSizeM,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: AppDimensions.fontSizeL,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
          height: AppDimensions.lineHeightNormal,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: AppDimensions.fontSizeM,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
          height: AppDimensions.lineHeightNormal,
        ),
        bodySmall: GoogleFonts.poppins(
          fontSize: AppDimensions.fontSizeS,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
        labelLarge: GoogleFonts.poppins(
          fontSize: AppDimensions.fontSizeL,
          fontWeight: FontWeight.w600,
          color: AppColors.textWhite,
          letterSpacing: 0.3,
        ),
        labelMedium: GoogleFonts.poppins(
          fontSize: AppDimensions.fontSizeM,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
        labelSmall: GoogleFonts.poppins(
          fontSize: AppDimensions.fontSizeXS,
          fontWeight: FontWeight.w400,
          color: AppColors.textHint,
        ),
      );

  // ── Input Decoration Theme ───────────────────────────────────────────────
  // Matches React: white bg, border-gray-300, rounded-lg (12px),
  // focus:ring-2 focus:ring-[#1A5C38]
  static InputDecorationTheme get _inputDecorationTheme =>
      InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputBg,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceL,
          vertical: AppDimensions.spaceM,
        ),
        hintStyle: GoogleFonts.poppins(
          fontSize: AppDimensions.fontSizeM,
          color: AppColors.textHint,
        ),
        labelStyle: GoogleFonts.poppins(
          fontSize: AppDimensions.fontSizeM,
          color: AppColors.textSecondary,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          borderSide: const BorderSide(
            color: AppColors.borderMedium,
            width: AppDimensions.borderWidth,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          borderSide: const BorderSide(
            color: AppColors.borderMedium,
            width: AppDimensions.borderWidth,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          borderSide: const BorderSide(
            color: AppColors.primaryGreen,
            width: AppDimensions.borderWidthMedium,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: AppDimensions.borderWidth,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: AppDimensions.borderWidthMedium,
          ),
        ),
        errorStyle: GoogleFonts.poppins(
          fontSize: AppDimensions.fontSizeXS,
          color: AppColors.error,
        ),
      );

  // ── Elevated Button Theme ───────────────────────────────────────────────
  static ElevatedButtonThemeData get _elevatedButtonTheme =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: AppColors.textWhite,
          minimumSize: const Size(double.infinity, AppDimensions.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          ),
          elevation: AppDimensions.elevationNone,
          textStyle: GoogleFonts.poppins(
            fontSize: AppDimensions.fontSizeL,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  // ── Outlined Button Theme ───────────────────────────────────────────────
  static OutlinedButtonThemeData get _outlinedButtonTheme =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textWhite,
          minimumSize: const Size(double.infinity, AppDimensions.buttonHeight),
          side: const BorderSide(
            color: AppColors.textWhite,
            width: AppDimensions.borderWidthMedium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: AppDimensions.fontSizeL,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  // ── Text Button Theme ───────────────────────────────────────────────────
  static TextButtonThemeData get _textButtonTheme => TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryGreen,
          textStyle: GoogleFonts.poppins(
            fontSize: AppDimensions.fontSizeM,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceS),
        ),
      );

  // ── Tab Bar Theme ───────────────────────────────────────────────────────
  // Matches React: active tab has border-b-2 border-[#1A5C38], inactive text-gray-400
  static TabBarThemeData get _tabBarThemeData => TabBarThemeData(
        labelColor: AppColors.primaryGreen,
        unselectedLabelColor: AppColors.textHint,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(
            color: AppColors.primaryGreen,
            width: 2.0,
          ),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: AppColors.borderLight,
        labelStyle: GoogleFonts.poppins(
          fontSize: AppDimensions.fontSizeL,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: AppDimensions.fontSizeL,
          fontWeight: FontWeight.w400,
        ),
        overlayColor: WidgetStateProperty.all(Colors.transparent),
      );
}
