/// Form validation utilities.
/// All validation logic lives here — never inline in widgets.
abstract final class AppValidators {
  /// Returns an error string if [value] is not a valid email, else null.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  /// Returns an error string if [value] is shorter than [minLength], else null.
  static String? password(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    return null;
  }

  /// Returns an error string if [value] is not a valid name, else null.
  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  /// Returns an error string if [value] is not a valid phone number, else null.
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    // Accepts optional +country-code followed by 7-15 digits
    final phoneRegex = RegExp(r'^\+?[0-9]{7,15}$');
    final stripped = value.trim().replaceAll(RegExp(r'\s+'), '');
    if (!phoneRegex.hasMatch(stripped)) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  /// Validates that [value] matches [original] (for confirm-password).
  static String? Function(String?) confirmPassword(String original) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return 'Please confirm your password';
      }
      if (value != original) {
        return 'Passwords do not match';
      }
      return null;
    };
  }

  /// Returns an error string if [value] is empty, else null.
  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
}
