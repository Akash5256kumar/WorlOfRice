/// All user-visible strings, centralized for easy localization later.
/// Never use raw string literals in UI widgets — always reference here.
abstract final class AppStrings {
  // ── App ──────────────────────────────────────────────────────────────────
  static const String appName = 'Joy World of Rice';
  static const String appTagline = 'Premium Rice, Delivered Fresh';
  static const String appSplashTagline = 'Heritage. Health. Flavour.';

  // ── Onboarding ───────────────────────────────────────────────────────────
  static const String onboardingSlide1Title = '150+ Premium\nVarieties';
  static const String onboardingSlide1Subtitle =
      'From Basmati to rare heritage grains';

  static const String onboardingSlide2Title = 'Freshly Packed for Delivery';
  static const String onboardingSlide2Subtitle =
      'Carefully handled from our store to your doorstep';

  static const String onboardingSlide3Title = 'Straight to Your\nDoorstep';
  static const String onboardingSlide3Subtitle = 'Fast delivery across India';

  static const String getStarted = 'Get Started';

  // ── Welcome ──────────────────────────────────────────────────────────────
  static const String welcomeTitle = 'Joy World of Rice';
  static const String welcomeSubtitle = 'Premium Rice, Trusted Since 1974';

  // ── Auth Tabs ────────────────────────────────────────────────────────────
  static const String login = 'Login';
  static const String signUp = 'Sign Up';

  // ── Login Form ───────────────────────────────────────────────────────────
  static const String emailLabel = 'Email';
  static const String emailHint = 'Enter your email';
  static const String emailPhoneLabel = 'EMAIL/PHONE';
  static const String emailPhoneHint = 'Enter email or phone';
  static const String passwordLabel = 'PASSWORD';
  static const String passwordHint = 'Enter your password';
  static const String rememberMe = 'REMEMBER ME';
  static const String forgotPassword = 'Forgot Password?';
  static const String loginTandC = '* By login I agree with all the ';
  static const String termsAndConditions = 'Terms & Conditions';
  static const String loginButton = 'SUBMIT';
  static const String orDivider = 'OR';
  static const String continueWithGoogle = 'Continue with Google';
  static const String dontHaveAccount = "Don't have an account? ";
  static const String signUpLink = 'Signup';

  // ── Sign Up Form ─────────────────────────────────────────────────────────
  static const String fullNameLabel = 'Full Name';
  static const String fullNameHint = 'Enter your name';
  static const String phoneLabel = 'Phone Number';
  static const String phoneHint = 'e.g. +91 9876543210';
  static const String confirmPasswordLabel = 'Confirm Password';
  static const String confirmPasswordHint = 'Re-enter your password';
  static const String signUpButton = 'Sign Up';
  static const String alreadyHaveAccount = 'Already have an account?';
  static const String loginLink = 'Login';

  // ── Validation ───────────────────────────────────────────────────────────
  static const String validationRequired = 'This field is required';
  static const String validationInvalidEmail = 'Enter a valid email address';
  static const String validationPasswordLength =
      'Password must be at least 6 characters';
  static const String validationNameLength =
      'Name must be at least 2 characters';

  // ── Errors ───────────────────────────────────────────────────────────────
  static const String errorGeneric = 'Something went wrong. Please try again.';
  static const String errorNetwork = 'Network error. Check your connection.';
  static const String errorInvalidCredentials =
      'Invalid email or password.';

  // ── Success ──────────────────────────────────────────────────────────────
  static const String successLogin = 'Logged in successfully!';
  static const String successSignUp = 'Account created! Please log in.';

  // ── Home Sections ─────────────────────────────────────────────────────────
  static const String homeHeroTitle = 'Premium Rice\nDelivered Fresh';
  static const String homeHeroSubtitle = 'Trusted by 5,000+ families since 1974';
  static const String homeShopNow = 'Shop Now';
  static const String homeCategories = 'CATEGORIES';
  static const String homeFeatured = 'FEATURED PRODUCTS';
  static const String homeWhyChooseUs = 'WHY CHOOSE US';
  static const String homeWhyQuality = 'Premium Quality';
  static const String homeWhyQualityDesc = '150+ varieties sourced direct';
  static const String homeWhyDelivery = 'Fast Delivery';
  static const String homeWhyDeliveryDesc = 'Straight to your doorstep';
  static const String homeWhyLegacy = '50 Yr Legacy';
  static const String homeWhyLegacyDesc = 'Trusted since 1974';

  // ── Navigation ────────────────────────────────────────────────────────────
  static const String navHome = 'Home';
  static const String navShop = 'Shop';
  static const String navCart = 'Cart';
  static const String navBlog = 'Blog';
  static const String navAccount = 'Account';

  // ── Placeholders ─────────────────────────────────────────────────────────
  static const String comingSoon = 'Coming Soon';
}
