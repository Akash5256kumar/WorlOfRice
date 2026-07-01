part of 'onboarding_bloc.dart';

/// All states emitted by [OnboardingBloc].
sealed class OnboardingState extends Equatable {
  const OnboardingState();

  @override
  List<Object?> get props => [];
}

/// Normal onboarding in-progress state.
final class OnboardingInProgress extends OnboardingState {
  const OnboardingInProgress({
    required this.currentPage,
    required this.totalPages,
  });

  final int currentPage;
  final int totalPages;

  /// Whether this is the last page (shows "Get Started" or changes CTA).
  bool get isLastPage => currentPage == totalPages - 1;

  @override
  List<Object?> get props => [currentPage, totalPages];
}

/// Emitted when the user has completed onboarding — navigate to welcome.
final class OnboardingDone extends OnboardingState {
  const OnboardingDone();
}
