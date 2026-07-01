/// Parsed response from `POST /auth/login`.
final class LoginResponse {
  const LoginResponse({
    required this.token,
    required this.email,
    this.isEmailVerified = 0,
    this.loginType = 'manual',
  });

  final String token;
  final String email;
  final int isEmailVerified;
  final String loginType;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] as String? ?? '',
      email: json['email'] as String? ?? '',
      isEmailVerified: json['is_email_verified'] as int? ?? 0,
      loginType: json['login_type'] as String? ?? 'manual',
    );
  }
}
