import '../../domain/usecases/auth_usecase.dart';

/// Mock implementation of [AuthUseCase] for development and testing.
///
/// Replace with a real implementation (Firebase, REST, etc.) when ready.
final class MockAuthUseCase implements AuthUseCase {
  @override
  Future<void> login({
    required String emailOrPhone,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(seconds: 2));
    if (password == 'wrong') {
      throw const AuthException('Invalid credentials.');
    }
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String confirmPassword,
    required String phone,
    String? fullName,
  }) async {
    await Future<void>.delayed(const Duration(seconds: 2));
    // No error in mock — always succeeds
  }

  @override
  Future<void> googleSignIn() async {
    await Future<void>.delayed(const Duration(seconds: 1));
    // Google Sign-In mock always succeeds
  }

  @override
  Future<void> logout() async {
    // Mock: nothing to clear
  }
}
