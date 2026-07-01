import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/auth_usecase.dart';
import '../../../../core/constants/app_strings.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Handles all authentication business logic.
///
/// Depends on [AuthUseCase] interface — completely decoupled from any
/// concrete implementation (Firebase, REST, mock, etc.).
///
/// The UI only dispatches events and reacts to states — zero business
/// logic lives in widgets.
final class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required AuthUseCase authUseCase})
      : _authUseCase = authUseCase,
        super(const AuthInitial()) {
    on<LoginSubmitted>(_onLoginSubmitted);
    on<SignUpSubmitted>(_onSignUpSubmitted);
    on<GoogleSignInRequested>(_onGoogleSignIn);
    on<AuthErrorDismissed>(_onErrorDismissed);
    on<LogoutRequested>(_onLogout);
  }

  final AuthUseCase _authUseCase;

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authUseCase.login(
        emailOrPhone: event.emailOrPhone,
        password: event.password,
      );
      emit(const AuthSuccess(message: AppStrings.successLogin));
    } on AuthException catch (e) {
      emit(AuthFailure(errorMessage: e.message));
    } catch (_) {
      emit(const AuthFailure(errorMessage: AppStrings.errorGeneric));
    }
  }

  Future<void> _onSignUpSubmitted(
    SignUpSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authUseCase.signUp(
        email: event.email,
        password: event.password,
        confirmPassword: event.confirmPassword,
        phone: event.phone,
        fullName: event.fullName,
      );
      emit(const AuthSuccess(message: AppStrings.successSignUp, isSignUp: true));
    } on AuthException catch (e) {
      emit(AuthFailure(errorMessage: e.message));
    } catch (_) {
      emit(const AuthFailure(errorMessage: AppStrings.errorGeneric));
    }
  }

  Future<void> _onGoogleSignIn(
    GoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authUseCase.googleSignIn();
      emit(const AuthSuccess(message: AppStrings.successLogin));
    } on AuthException catch (e) {
      emit(AuthFailure(errorMessage: e.message));
    } catch (_) {
      emit(const AuthFailure(errorMessage: AppStrings.errorGeneric));
    }
  }

  void _onErrorDismissed(
    AuthErrorDismissed event,
    Emitter<AuthState> emit,
  ) {
    emit(const AuthInitial());
  }

  Future<void> _onLogout(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authUseCase.logout(); // clears JWT from SharedPreferences
    emit(const AuthLoggedOut());
  }
}
