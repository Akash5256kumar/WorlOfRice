import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../bloc/auth_bloc.dart';

// ── Country code data ────────────────────────────────────────────────────────

class _CountryCode {
  const _CountryCode(this.flag, this.dialCode, this.name);
  final String flag;
  final String dialCode;
  final String name;
}

const _countryCodes = [
  _CountryCode('🇮🇳', '+91', 'India'),
  _CountryCode('🇺🇸', '+1', 'USA'),
  _CountryCode('🇬🇧', '+44', 'UK'),
  _CountryCode('🇦🇪', '+971', 'UAE'),
  _CountryCode('🇸🇬', '+65', 'Singapore'),
  _CountryCode('🇦🇺', '+61', 'Australia'),
  _CountryCode('🇨🇦', '+1', 'Canada'),
];

// ── Widget ───────────────────────────────────────────────────────────────────

/// Login form — email/phone + country code picker, password, remember me, T&C.
class LoginForm extends StatefulWidget {
  const LoginForm({super.key, required this.onSwitchToSignUp});

  final VoidCallback onSwitchToSignUp;

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailPhoneFocus = FocusNode();
  final _passwordFocus = FocusNode();

  _CountryCode _selectedCountry = _countryCodes.first;
  bool _rememberMe = false;

  // True when the input looks like an email — hides country code relevance.
  bool get _isEmail => _emailPhoneController.text.contains('@');

  /// Full value sent to the API: email as-is, phone with country prefix.
  String get _resolvedInput {
    final raw = _emailPhoneController.text.trim();
    if (_isEmail) return raw;
    if (raw.startsWith('+')) return raw;
    return '${_selectedCountry.dialCode}$raw';
  }

  @override
  void initState() {
    super.initState();
    // Rebuild when input changes so country picker opacity reacts.
    _emailPhoneController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailPhoneController.dispose();
    _passwordController.dispose();
    _emailPhoneFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _onLoginPressed(BuildContext context) {
    if (_formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();
      context.read<AuthBloc>().add(
            LoginSubmitted(
              emailOrPhone: _resolvedInput,
              password: _passwordController.text,
            ),
          );
    }
  }

  void _showCountryPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXL),
        ),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppDimensions.spaceM),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderMedium,
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            ),
          ),
          const SizedBox(height: AppDimensions.spaceL),
          Text(
            'Select Country Code',
            style: GoogleFonts.poppins(
              fontSize: AppDimensions.fontSizeL,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceS),
          const Divider(),
          ..._countryCodes.map(
            (c) => ListTile(
              leading: Text(c.flag, style: const TextStyle(fontSize: 24)),
              title: Text(
                '${c.name}  (${c.dialCode})',
                style: GoogleFonts.poppins(
                  fontSize: AppDimensions.fontSizeM,
                  color: AppColors.textPrimary,
                ),
              ),
              trailing: _selectedCountry.dialCode == c.dialCode &&
                      _selectedCountry.name == c.name
                  ? const Icon(Icons.check, color: AppColors.primaryGreen)
                  : null,
              onTap: () {
                setState(() => _selectedCountry = c);
                Navigator.pop(context);
              },
            ),
          ),
          const SizedBox(height: AppDimensions.spaceL),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _EmailPhoneField(
                controller: _emailPhoneController,
                focusNode: _emailPhoneFocus,
                nextFocus: _passwordFocus,
                selectedCountry: _selectedCountry,
                isEmail: _isEmail,
                enabled: !isLoading,
                onPickerTap: () => _showCountryPicker(context),
              ),
              const SizedBox(height: AppDimensions.spaceXL),
              _PasswordField(
                controller: _passwordController,
                focusNode: _passwordFocus,
                enabled: !isLoading,
                onSubmitted: (_) => _onLoginPressed(context),
              ),
              const SizedBox(height: AppDimensions.spaceL),
              _RememberMeRow(
                value: _rememberMe,
                enabled: !isLoading,
                onChanged: (v) => setState(() => _rememberMe = v ?? false),
              ),
              const SizedBox(height: AppDimensions.spaceM),
              const _TandCText(),
              const SizedBox(height: AppDimensions.spaceXL),
              // ── Server error banner ──────────────────────────────────────
              if (state is AuthFailure) ...[
                _AuthErrorBanner(
                  message: state.errorMessage,
                  onDismiss: () => context
                      .read<AuthBloc>()
                      .add(const AuthErrorDismissed()),
                ),
                const SizedBox(height: AppDimensions.spaceXL),
              ],
              AppPrimaryButton(
                label: AppStrings.loginButton,
                onPressed: () => _onLoginPressed(context),
                isLoading: isLoading,
              ),
              const SizedBox(height: AppDimensions.spaceXXL),
              _SwitchToSignUpRow(onTap: widget.onSwitchToSignUp),
            ],
          ),
        );
      },
    );
  }
}

// ── Private sub-widgets ──────────────────────────────────────────────────────

/// Combined country-code picker + email/phone text field.
class _EmailPhoneField extends StatelessWidget {
  const _EmailPhoneField({
    required this.controller,
    required this.focusNode,
    required this.nextFocus,
    required this.selectedCountry,
    required this.isEmail,
    required this.enabled,
    required this.onPickerTap,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode nextFocus;
  final _CountryCode selectedCountry;
  final bool isEmail;
  final bool enabled;
  final VoidCallback onPickerTap;

  String? _validate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email or phone number is required';
    }
    final v = value.trim();
    if (v.contains('@')) {
      final emailRe = RegExp(
        r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
      );
      if (!emailRe.hasMatch(v)) return 'Enter a valid email address';
    } else {
      final stripped = v.replaceAll(RegExp(r'\s+'), '');
      final phoneRe = RegExp(r'^\+?[0-9]{7,15}$');
      if (!phoneRe.hasMatch(stripped)) return 'Enter a valid phone number';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(text: AppStrings.emailPhoneLabel),
        const SizedBox(height: AppDimensions.spaceS),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Country code picker (dimmed when user types an email)
            Opacity(
              opacity: isEmail ? 0.4 : 1.0,
              child: GestureDetector(
                onTap: (enabled && !isEmail) ? onPickerTap : null,
                child: Container(
                  height: AppDimensions.inputHeight,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spaceM,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.inputBg,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                    border: Border.all(color: AppColors.borderMedium),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        selectedCountry.flag,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        selectedCountry.dialCode,
                        style: GoogleFonts.poppins(
                          fontSize: AppDimensions.fontSizeM,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.arrow_drop_down,
                        size: AppDimensions.iconSizeL,
                        color: AppColors.textPrimary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.spaceS),
            // Email / phone text input
            Expanded(
              child: TextFormField(
                controller: controller,
                focusNode: focusNode,
                enabled: enabled,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [
                  AutofillHints.email,
                  AutofillHints.telephoneNumber,
                ],
                validator: _validate,
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(nextFocus),
                style: GoogleFonts.poppins(
                  fontSize: AppDimensions.fontSizeM,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: AppStrings.emailPhoneHint,
                  hintStyle: GoogleFonts.poppins(
                    fontSize: AppDimensions.fontSizeM,
                    color: AppColors.textHint,
                  ),
                  filled: true,
                  fillColor: AppColors.inputBg,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spaceL,
                    vertical: AppDimensions.spaceM,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                    borderSide: const BorderSide(color: AppColors.borderMedium),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                    borderSide: const BorderSide(color: AppColors.borderMedium),
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
                    borderSide: const BorderSide(color: AppColors.error),
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
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PasswordField extends StatefulWidget {
  const _PasswordField({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final ValueChanged<String> onSubmitted;

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscure = true;

  String? _validate(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(text: AppStrings.passwordLabel),
        const SizedBox(height: AppDimensions.spaceS),
        TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          enabled: widget.enabled,
          obscureText: _obscure,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          validator: _validate,
          onFieldSubmitted: widget.onSubmitted,
          style: GoogleFonts.poppins(
            fontSize: AppDimensions.fontSizeM,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: AppStrings.passwordHint,
            hintStyle: GoogleFonts.poppins(
              fontSize: AppDimensions.fontSizeM,
              color: AppColors.textHint,
            ),
            filled: true,
            fillColor: AppColors.inputBg,
            suffixIcon: IconButton(
              icon: Icon(
                _obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textHint,
                size: AppDimensions.iconSizeM,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
              splashRadius: AppDimensions.spaceXXL,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spaceL,
              vertical: AppDimensions.spaceM,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              borderSide: const BorderSide(color: AppColors.borderMedium),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              borderSide: const BorderSide(color: AppColors.borderMedium),
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
              borderSide: const BorderSide(color: AppColors.error),
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
          ),
        ),
      ],
    );
  }
}

class _RememberMeRow extends StatelessWidget {
  const _RememberMeRow({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final bool value;
  final bool enabled;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: enabled ? onChanged : null,
          activeColor: AppColors.primaryGreen,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
        const SizedBox(width: AppDimensions.spaceXS),
        GestureDetector(
          onTap: enabled ? () => onChanged(!value) : null,
          child: Text(
            AppStrings.rememberMe,
            style: GoogleFonts.poppins(
              fontSize: AppDimensions.fontSizeM,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: enabled ? () {} : null,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            AppStrings.forgotPassword,
            style: GoogleFonts.poppins(
              fontSize: AppDimensions.fontSizeM,
              fontWeight: FontWeight.w500,
              color: AppColors.accentGold,
            ),
          ),
        ),
      ],
    );
  }
}

class _TandCText extends StatefulWidget {
  const _TandCText();

  @override
  State<_TandCText> createState() => _TandCTextState();
}

class _TandCTextState extends State<_TandCText> {
  final _recognizer = TapGestureRecognizer();

  @override
  void initState() {
    super.initState();
    _recognizer.onTap = _openTerms;
  }

  @override
  void dispose() {
    _recognizer.dispose();
    super.dispose();
  }

  Future<void> _openTerms() async {
    final uri = Uri.parse('https://www.worldofrice.in/terms-and-conditions');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: GoogleFonts.poppins(
          fontSize: AppDimensions.fontSizeS,
          color: AppColors.textSecondary,
        ),
        children: [
          const TextSpan(text: AppStrings.loginTandC),
          TextSpan(
            text: AppStrings.termsAndConditions,
            recognizer: _recognizer,
            style: GoogleFonts.poppins(
              fontSize: AppDimensions.fontSizeS,
              color: AppColors.primaryGreen,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: GoogleFonts.poppins(
          fontSize: AppDimensions.fontSizeS,
          fontWeight: FontWeight.w700,
          color: AppColors.accentGold,
          letterSpacing: 0.5,
        ),
        children: [
          TextSpan(text: text),
          const TextSpan(text: ' *'),
        ],
      ),
    );
  }
}

// ── Inline server-error banner ────────────────────────────────────────────────

class _AuthErrorBanner extends StatelessWidget {
  const _AuthErrorBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: AppDimensions.fontSizeS,
                fontWeight: FontWeight.w500,
                color: AppColors.error,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onDismiss,
            child: Icon(
              Icons.close_rounded,
              color: AppColors.error.withValues(alpha: 0.7),
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchToSignUpRow extends StatelessWidget {
  const _SwitchToSignUpRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          AppStrings.dontHaveAccount,
          style: GoogleFonts.poppins(
            fontSize: AppDimensions.fontSizeM,
            color: AppColors.textSecondary,
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            AppStrings.signUpLink,
            style: GoogleFonts.poppins(
              fontSize: AppDimensions.fontSizeM,
              fontWeight: FontWeight.w700,
              color: AppColors.accentGold,
            ),
          ),
        ),
      ],
    );
  }
}
