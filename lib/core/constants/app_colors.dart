import 'package:flutter/material.dart';

/// All brand and semantic colors for Joy World of Rice.
/// Aligned with the React reference design.
/// Never use [Color] literals directly in widgets — always reference here.
abstract final class AppColors {
  // ── Brand ─────────────────────────────────────────────────────────────────
  static const Color primaryGreen = Color(0xFF1A5C38);      // React: #1A5C38
  static const Color primaryGreenDark = Color(0xFF155030);  // React hover: #155030
  static const Color primaryGreenLight = Color(0xFF4A8A2C); // tint for icon bg
  static const Color darkBrown = Color(0xFF2C1F0E);         // React: #2C1F0E
  static const Color accentGold = Color(0xFFD4A017);        // React: #D4A017
  static const Color accentGoldLight = Color(0xFFF0C040);   // lighter gold tint
  static const Color ctaRed = Color(0xFFE74C1F);            // React: #E74C1F (Buy Now / Checkout)
  static const Color navy = Color(0xFF1C3557);               // React: #1C3557

  // ── Backgrounds ───────────────────────────────────────────────────────────
  static const Color scaffoldBg = Color(0xFFF5F0E8);        // React: #F5F0E8
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color inputBg = Color(0xFFFFFFFF);
  static const Color onboardingGradientTop = Color(0xFFD6CFC6);
  static const Color onboardingGradientBottom = Color(0xFF4A4740);

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B6B);     // React: #6B6B6B
  static const Color textHint = Color(0xFFAAAAAA);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textOnDark = Color(0xFFEEEEEE);

  // ── Borders / Dividers ────────────────────────────────────────────────────
  static const Color borderLight = Color(0xFFE0E0E0);       // React: border-gray-200
  static const Color borderMedium = Color(0xFFBDBDBD);      // React: border-gray-300
  static const Color divider = Color(0xFFEEEEEE);

  // ── Status ────────────────────────────────────────────────────────────────
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF388E3C);
  static const Color warning = Color(0xFFD4A017);           // gold for pending state

  // ── Bottom Navigation ─────────────────────────────────────────────────────
  static const Color bottomNavBg = Color(0xFF2C1F0E);       // React: #2C1F0E
  static const Color bottomNavBorder = Color(0xFF4A3A2A);   // React: border-[#4a3a2a]

  // ── Overlays ──────────────────────────────────────────────────────────────
  static const Color overlayDark = Color(0xFF000000);
  static const Color overlayLight = Color(0x33FFFFFF);

  // ── Misc ──────────────────────────────────────────────────────────────────
  static const Color transparent = Colors.transparent;
}
