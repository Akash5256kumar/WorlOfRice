part of 'payment_bloc.dart';

sealed class PaymentState {
  const PaymentState();
}

/// Nothing started yet.
final class PaymentInitial extends PaymentState {
  const PaymentInitial();
}

/// Fetching Razorpay order details from the backend.
final class PaymentLoading extends PaymentState {
  const PaymentLoading();
}

/// Backend returned Razorpay options — page should open Razorpay checkout.
final class PaymentReadyToCheckout extends PaymentState {
  const PaymentReadyToCheckout(this.details);

  final RazorpayOrderDetails details;
}

/// Confirming the payment with the backend after Razorpay success callback.
final class PaymentConfirming extends PaymentState {
  const PaymentConfirming();
}

/// Payment fully confirmed — show success UI.
final class PaymentSuccess extends PaymentState {
  const PaymentSuccess({required this.paymentId, required this.appOrderId});

  final String paymentId;
  final int appOrderId;
}

/// COD order placed — show success UI.
final class OrderPlaced extends PaymentState {
  const OrderPlaced({
    required this.orderId,
    required this.totalAmount,
    required this.status,
  });

  final int orderId;
  final double totalAmount;
  final String status;
}

/// Either backend call failed or Razorpay returned an error.
final class PaymentFailure extends PaymentState {
  const PaymentFailure(this.message);

  final String message;
}
