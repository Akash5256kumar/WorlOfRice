part of 'auth_bloc.dart';

/// All states emitted by [AuthBloc].
sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Idle — no operation in progress.
final class AuthInitial extends AuthState {
  const AuthInitial();
}

/// An auth operation (login / sign up / google) is in progress.
final class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Auth operation succeeded.
/// [isSignUp] is true for registration — the UI should redirect to Login tab
/// rather than to Home.
final class AuthSuccess extends AuthState {
  const AuthSuccess({required this.message, this.isSignUp = false});

  final String message;
  final bool isSignUp;

  @override
  List<Object?> get props => [message, isSignUp];
}

/// Auth operation failed.
final class AuthFailure extends AuthState {
  const AuthFailure({required this.errorMessage});

  final String errorMessage;

  @override
  List<Object?> get props => [errorMessage];
}

/// User successfully logged out — navigate back to onboarding/welcome.
final class AuthLoggedOut extends AuthState {
  const AuthLoggedOut();
}
