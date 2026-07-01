part of 'onboarding_bloc.dart';

/// All events the [OnboardingBloc] can handle.
sealed class OnboardingEvent extends Equatable {
  const OnboardingEvent();

  @override
  List<Object?> get props => [];
}

/// Fired when the user swipes or the [PageView] changes pages.
final class OnboardingPageChanged extends OnboardingEvent {
  const OnboardingPageChanged({required this.pageIndex});

  final int pageIndex;

  @override
  List<Object?> get props => [pageIndex];
}

/// Fired when the user taps "Get Started".
final class OnboardingCompleted extends OnboardingEvent {
  const OnboardingCompleted();
}
