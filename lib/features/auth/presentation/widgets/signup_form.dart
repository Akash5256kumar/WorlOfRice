import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/app_primary_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../bloc/auth_bloc.dart';

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

/// Sign Up form tab — full name, email, phone, password, confirm password.
///
/// All state management is delegated to [AuthBloc].
/// This widget contains zero business logic.
class SignUpForm extends StatefulWidget {
  const SignUpForm({super.key, required this.onSwitchToLogin});

  /// Called when the user taps "Login" link at the bottom.
  final VoidCallback onSwitchToLogin;

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  void _onSignUpPressed(BuildContext context) {
    if (_formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();
      context.read<AuthBloc>().add(
            SignUpSubmitted(
              email: _emailController.text.trim(),
              password: _passwordController.text,
              confirmPassword: _confirmPasswordController.text,
              phone: _phoneController.text.trim(),
              fullName: _nameController.text.trim(),
            ),
          );
    }
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
              AppTextField(
                label: AppStrings.fullNameLabel,
                hint: AppStrings.fullNameHint,
                controller: _nameController,
                focusNode: _nameFocus,
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                validator: AppValidators.fullName,
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_emailFocus),
                enabled: !isLoading,
              ),
              const SizedBox(height: AppDimensions.spaceXL),
              AppTextField(
                label: AppStrings.emailLabel,
                hint: AppStrings.emailHint,
                controller: _emailController,
                focusNode: _emailFocus,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: AppValidators.email,
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_phoneFocus),
                enabled: !isLoading,
              ),
              const SizedBox(height: AppDimensions.spaceXL),
              AppTextField(
                label: AppStrings.phoneLabel,
                hint: AppStrings.phoneHint,
                controller: _phoneController,
                focusNode: _phoneFocus,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.telephoneNumber],
                validator: AppValidators.phone,
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_passwordFocus),
                enabled: !isLoading,
              ),
              const SizedBox(height: AppDimensions.spaceXL),
              AppTextField(
                label: AppStrings.passwordLabel,
                hint: AppStrings.passwordHint,
                controller: _passwordController,
                focusNode: _passwordFocus,
                obscureText: true,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                validator: AppValidators.password,
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_confirmPasswordFocus),
                enabled: !isLoading,
              ),
              const SizedBox(height: AppDimensions.spaceXL),
              AppTextField(
                label: AppStrings.confirmPasswordLabel,
                hint: AppStrings.confirmPasswordHint,
                controller: _confirmPasswordController,
                focusNode: _confirmPasswordFocus,
                obscureText: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  // Read _passwordController.text at validation time, not build time
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _onSignUpPressed(context),
                enabled: !isLoading,
              ),
              const SizedBox(height: AppDimensions.spaceXXL),
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
                label: AppStrings.signUpButton,
                onPressed: () => _onSignUpPressed(context),
                isLoading: isLoading,
              ),
              const SizedBox(height: AppDimensions.spaceXXL),
              _SwitchToLoginRow(onTap: widget.onSwitchToLogin),
            ],
          ),
        );
      },
    );
  }
}

// ── Private sub-widgets ──────────────────────────────────────────────────────

class _SwitchToLoginRow extends StatelessWidget {
  const _SwitchToLoginRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          AppStrings.alreadyHaveAccount,
          style: GoogleFonts.poppins(
            fontSize: AppDimensions.fontSizeM,
            color: AppColors.textSecondary,
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            AppStrings.loginLink,
            style: GoogleFonts.poppins(
              fontSize: AppDimensions.fontSizeM,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
