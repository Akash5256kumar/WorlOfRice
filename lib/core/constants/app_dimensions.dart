/// All spacing, sizing, radius, and font-size constants.
/// Never use raw numeric literals in widgets — always reference here.
abstract final class AppDimensions {
  // ── Spacing / Padding ────────────────────────────────────────────────────
  static const double spaceXXS = 2.0;
  static const double spaceXS = 4.0;
  static const double spaceS = 8.0;
  static const double spaceM = 12.0;
  static const double spaceL = 16.0;
  static const double spaceXL = 20.0;
  static const double spaceXXL = 24.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;
  static const double space56 = 56.0;
  static const double space64 = 64.0;
  static const double space80 = 80.0;
  static const double space100 = 100.0;
  static const double space120 = 120.0;

  // ── Border Radius ────────────────────────────────────────────────────────
  static const double radiusXS = 4.0;
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusFull = 999.0;

  // ── Font Sizes ───────────────────────────────────────────────────────────
  static const double fontSizeXS = 10.0;
  static const double fontSizeS = 12.0;
  static const double fontSizeM = 14.0;
  static const double fontSizeL = 16.0;
  static const double fontSizeXL = 18.0;
  static const double fontSizeXXL = 22.0;
  static const double fontSizeDisplay = 28.0;
  static const double fontSizeHero = 34.0;

  // ── Line Heights ─────────────────────────────────────────────────────────
  static const double lineHeightTight = 1.2;
  static const double lineHeightNormal = 1.5;
  static const double lineHeightLoose = 1.8;

  // ── Components ───────────────────────────────────────────────────────────
  static const double buttonHeight = 54.0;
  static const double inputHeight = 54.0;
  static const double iconSizeS = 16.0;
  static const double iconSizeM = 20.0;
  static const double iconSizeL = 24.0;
  static const double iconSizeXL = 32.0;

  // ── Logo ─────────────────────────────────────────────────────────────────
  static const double logoSize = 110.0;
  static const double logoSizeSmall = 112.0; // React auth: w-28 h-28 = 112px
  static const double logoSizeSplash = 140.0;

  // ── Page Indicator (React: w-2 h-2 inactive, w-8 h-2 active) ────────────
  static const double indicatorDotWidth = 8.0;
  static const double indicatorDotHeight = 8.0;
  static const double indicatorDotSpacing = 8.0;

  // ── Border Width ─────────────────────────────────────────────────────────
  static const double borderWidth = 1.0;
  static const double borderWidthMedium = 1.5;

  // ── Elevation ────────────────────────────────────────────────────────────
  static const double elevationNone = 0.0;
  static const double elevationLow = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;

  // ── Opacity ──────────────────────────────────────────────────────────────
  static const double opacityDisabled = 0.5;
  static const double opacitySubtle = 0.7;
}
