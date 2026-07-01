/// Abstract contract for auth operations.
///
/// By depending on this interface, the BLoC is decoupled from any
/// concrete implementation (Firebase, REST, mock, etc.).
abstract interface class AuthUseCase {
  /// Logs in with an email or phone number and [password].
  /// Throws [AuthException] on failure.
  Future<void> login({required String emailOrPhone, required String password});

  /// Registers a new user.
  /// Throws [AuthException] on failure.
  Future<void> signUp({
    required String email,
    required String password,
    required String confirmPassword,
    required String phone,
    String? fullName,
  });

  /// Initiates Google Sign-In flow.
  /// Throws [AuthException] on failure.
  Future<void> googleSignIn();

  /// Clears the stored token and logs the user out.
  Future<void> logout();
}

/// Exception thrown by auth operations.
final class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => 'AuthException: $message';
}
