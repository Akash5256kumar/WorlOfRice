part of 'checkout_cubit.dart';

sealed class CheckoutState {
  const CheckoutState();
}

/// No address selected yet — waiting for user input.
final class CheckoutInitial extends CheckoutState {
  const CheckoutInitial();
}

/// Zone API call in-flight — recalculating charges.
final class CheckoutCalculating extends CheckoutState {
  const CheckoutCalculating();
}

/// Charges computed — ready to display and place order.
final class CheckoutReady extends CheckoutState {
  const CheckoutReady(this.summary);
  final CheckoutSummary summary;
}

/// Zone API call failed.
final class CheckoutError extends CheckoutState {
  const CheckoutError(this.message);
  final String message;
}
