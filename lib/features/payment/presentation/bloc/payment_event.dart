part of 'payment_bloc.dart';

sealed class PaymentEvent {
  const PaymentEvent();
}

/// Triggered when the user taps "Proceed to Pay".
/// The bloc fetches Razorpay order details from the backend.
final class PaymentCheckoutStarted extends PaymentEvent {
  const PaymentCheckoutStarted({
    required this.appOrderId,
    required this.customerId,
    required this.amountInPaise,
  });

  final int appOrderId;
  final int customerId;
  final int amountInPaise;
}

/// Opens Razorpay directly with the provided key — no backend order-creation
/// call required. Used for testing and when the order API is not yet wired.
final class PaymentDirectCheckoutStarted extends PaymentEvent {
  const PaymentDirectCheckoutStarted({
    required this.amountInPaise,
    required this.razorpayKeyId,
    this.customerName,
    this.customerEmail,
    this.customerPhone,
    this.description,
  });

  final int amountInPaise;
  final String razorpayKeyId;
  final String? customerName;
  final String? customerEmail;
  final String? customerPhone;
  final String? description;
}

/// Triggered by the page after Razorpay returns a success callback.
final class PaymentRazorpaySucceeded extends PaymentEvent {
  const PaymentRazorpaySucceeded({
    required this.paymentId,
    required this.razorpayOrderId,
    required this.signature,
    required this.appOrderId,
  });

  final String paymentId;
  final String razorpayOrderId;
  final String signature;
  final int appOrderId;
}

/// Triggered by the page after Razorpay returns a failure callback.
final class PaymentRazorpayFailed extends PaymentEvent {
  const PaymentRazorpayFailed({required this.code, required this.description});

  final int code;
  final String description;
}

/// Place a Cash on Delivery order via POST /customer/order/place.
final class PaymentCODStarted extends PaymentEvent {
  const PaymentCODStarted({
    required this.address,
    required this.cartItems,
    required this.orderAmount,
    this.deliveryCharge = 0,
    this.taxAmount = 0,
    this.distance = 0,
  });

  final AddressModel address;
  final List<CartItemModel> cartItems;
  final double orderAmount;

  /// Delivery charge shown in the bill (passed to the API).
  final double deliveryCharge;

  /// Tax amount shown in the bill (passed to the API).
  final double taxAmount;

  /// Delivery distance in km (passed to the API).
  final double distance;
}

/// Reset state (e.g., when navigating back from success screen).
final class PaymentReset extends PaymentEvent {
  const PaymentReset();
}
