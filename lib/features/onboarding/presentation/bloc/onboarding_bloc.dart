import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'onboarding_event.dart';
part 'onboarding_state.dart';

/// Manages the state of the onboarding carousel.
///
/// Responsibilities:
/// - Track which slide is currently displayed.
/// - Signal when onboarding is complete so the UI can navigate.
///
/// The business logic (which page is "last", validation, etc.) lives here
/// and is completely decoupled from the widget tree.
final class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingBloc({required int totalPages})
      : _totalPages = totalPages,
        super(OnboardingInProgress(currentPage: 0, totalPages: totalPages)) {
    on<OnboardingPageChanged>(_onPageChanged);
    on<OnboardingCompleted>(_onCompleted);
  }

  final int _totalPages;

  void _onPageChanged(
    OnboardingPageChanged event,
    Emitter<OnboardingState> emit,
  ) {
    emit(
      OnboardingInProgress(
        currentPage: event.pageIndex,
        totalPages: _totalPages,
      ),
    );
  }

  void _onCompleted(
    OnboardingCompleted event,
    Emitter<OnboardingState> emit,
  ) {
    emit(const OnboardingDone());
  }
}
