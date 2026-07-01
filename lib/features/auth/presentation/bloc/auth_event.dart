part of 'auth_bloc.dart';

/// All events the [AuthBloc] can handle.
sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// User tapped the Login button.
final class LoginSubmitted extends AuthEvent {
  const LoginSubmitted({
    required this.emailOrPhone,
    required this.password,
  });

  final String emailOrPhone;
  final String password;

  @override
  List<Object?> get props => [emailOrPhone, password];
}

/// User tapped the Sign Up button.
final class SignUpSubmitted extends AuthEvent {
  const SignUpSubmitted({
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.phone,
    required this.fullName,
  });

  final String email;
  final String password;
  final String confirmPassword;
  final String phone;
  final String fullName;

  @override
  List<Object?> get props => [email, password, confirmPassword, phone, fullName];
}

/// User tapped "Continue with Google".
final class GoogleSignInRequested extends AuthEvent {
  const GoogleSignInRequested();
}

/// Auth error was acknowledged — reset to initial.
final class AuthErrorDismissed extends AuthEvent {
  const AuthErrorDismissed();
}

/// User requested to log out.
final class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}
