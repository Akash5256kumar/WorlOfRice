import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../cart/data/models/cart_item_model.dart';
import '../../../customer/data/models/address_model.dart';
import '../../data/models/payment_model.dart';
import '../../data/repositories/payment_repository.dart';

part 'payment_event.dart';
part 'payment_state.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  PaymentBloc({PaymentRepository? repository})
      : _repo = repository ?? PaymentRepository(),
        super(const PaymentInitial()) {
    on<PaymentCheckoutStarted>(_onCheckoutStarted);
    on<PaymentDirectCheckoutStarted>(_onDirectCheckoutStarted);
    on<PaymentCODStarted>(_onCODStarted);
    on<PaymentRazorpaySucceeded>(_onRazorpaySucceeded);
    on<PaymentRazorpayFailed>(_onRazorpayFailed);
    on<PaymentReset>(_onReset);
  }

  final PaymentRepository _repo;

  // ── Backend-driven checkout (requires a valid appOrderId) ─────────────────

  Future<void> _onCheckoutStarted(
      PaymentCheckoutStarted event, Emitter<PaymentState> emit) async {
    emit(const PaymentLoading());
    try {
      final details = await _repo.initiatePayment(
        appOrderId: event.appOrderId,
        customerId: event.customerId,
        amountInPaise: event.amountInPaise,
      );
      debugPrint(
          '[PaymentBloc] ready: orderId=${details.razorpayOrderId} amount=${details.amountInPaise}');
      emit(PaymentReadyToCheckout(details));
    } catch (e) {
      debugPrint('[PaymentBloc] checkout error: $e');
      emit(PaymentFailure(e.toString()));
    }
  }

  // ── Cash on Delivery ──────────────────────────────────────────────────────

  Future<void> _onCODStarted(
      PaymentCODStarted event, Emitter<PaymentState> emit) async {
    emit(const PaymentLoading());
    try {
      final order = await _repo.placeOrder(
        address: event.address,
        cartItems: event.cartItems,
        paymentMethod: 'cash_on_delivery',
        orderAmount: event.orderAmount,
        deliveryCharge: event.deliveryCharge,
        taxAmount: event.taxAmount,
        distance: event.distance,
      );
      debugPrint('[PaymentBloc] COD order placed: #${order.orderId}');
      emit(OrderPlaced(
        orderId: order.orderId,
        totalAmount: order.totalAmount,
        status: order.status,
      ));
    } catch (e) {
      debugPrint('[PaymentBloc] COD error: $e');
      emit(PaymentFailure(e.toString()));
    }
  }

  // ── Direct Razorpay checkout (no backend order call) ─────────────────────

  void _onDirectCheckoutStarted(
      PaymentDirectCheckoutStarted event, Emitter<PaymentState> emit) {
    debugPrint(
        '[PaymentBloc] direct checkout: key=${event.razorpayKeyId} amount=${event.amountInPaise}');

    final details = RazorpayOrderDetails(
      razorpayOrderId: '', // no backend order — Razorpay allows this for testing
      amountInPaise: event.amountInPaise,
      currency: 'INR',
      keyId: event.razorpayKeyId,
      appOrderId: 0,
      customerName: event.customerName,
      customerEmail: event.customerEmail,
      customerPhone: event.customerPhone,
      description: event.description ?? 'World of Rice Order',
    );

    emit(PaymentReadyToCheckout(details));
  }

  // ── Razorpay success callback ──────────────────────────────────────────────

  Future<void> _onRazorpaySucceeded(
      PaymentRazorpaySucceeded event, Emitter<PaymentState> emit) async {
    emit(const PaymentConfirming());
    try {
      // Only call the backend confirmation if there was a real app order ID.
      if (event.appOrderId > 0) {
        await _repo.confirmPayment(
          appOrderId: event.appOrderId,
          razorpayOrderId: event.razorpayOrderId,
          razorpayPaymentId: event.paymentId,
          razorpaySignature: event.signature,
        );
      }
      debugPrint('[PaymentBloc] payment confirmed: ${event.paymentId}');
      emit(PaymentSuccess(
          paymentId: event.paymentId, appOrderId: event.appOrderId));
    } catch (e) {
      debugPrint('[PaymentBloc] confirm error (non-fatal): $e');
      // Still treat as success since Razorpay already collected the payment.
      emit(PaymentSuccess(
          paymentId: event.paymentId, appOrderId: event.appOrderId));
    }
  }

  // ── Razorpay failure callback ──────────────────────────────────────────────

  void _onRazorpayFailed(
      PaymentRazorpayFailed event, Emitter<PaymentState> emit) {
    debugPrint(
        '[PaymentBloc] Razorpay error ${event.code}: ${event.description}');
    emit(PaymentFailure(
        'Payment failed (${event.code}): ${event.description}'));
  }

  // ── Reset ─────────────────────────────────────────────────────────────────

  void _onReset(PaymentReset event, Emitter<PaymentState> emit) {
    emit(const PaymentInitial());
  }
}
