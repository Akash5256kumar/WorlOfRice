import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/api_constants.dart';
import '../../../../core/services/api_service.dart';
import '../../../cart/data/models/cart_item_model.dart';
import '../../../customer/data/models/address_model.dart';
import '../models/payment_model.dart';

class PaymentRepository {
  PaymentRepository({ApiService? service}) : _service = service ?? ApiService();

  final ApiService _service;

  /// Places an order via POST /customer/order/place.
  ///
  /// Sends the full payload expected by the API, including address fields,
  /// cart items, store/zone IDs, and payment details.
  ///
  /// [deliveryCharge], [taxAmount], [distance] must be passed from the UI
  /// so the backend's total validation matches exactly.
  Future<PlacedOrderModel> placeOrder({
    required AddressModel address,
    required List<CartItemModel> cartItems,
    required String paymentMethod,
    required double orderAmount,
    double deliveryCharge = 0,
    double taxAmount = 0,
    double distance = 0,
  }) async {
    final storeId =
        cartItems.isNotEmpty ? (cartItems.first.product?.storeId ?? 0) : 0;

    // zone_id comes from the delivery address (API returns `zone_id` on address).
    // The web app sends this as an array: [2].
    final zoneId = address.zoneId;

    // The API's `address` field is always null in address/list responses.
    // Use `additional_information` as the full address string — this is what
    // the web app sends as `address` during checkout.
    final safeAddress = address.checkoutAddress;

    // Backend expects `cart` as a JSON-encoded STRING — it calls json_decode($cart)
    // server-side. Each item's `variation` is always a List inside that string.
    final cartList = cartItems.map((i) => i.toJson()).toList();
    final cartJson = jsonEncode(cartList);

    debugPrint('[PaymentRepo] placeOrder → storeId=$storeId zoneId=$zoneId '
        'orderAmount=$orderAmount deliveryCharge=$deliveryCharge '
        'address="$safeAddress"');

    final data = await _service.post(
      ApiConstants.orderPlace,
      {
        'delivery_address_id': address.id,
        'address_type': address.addressType,
        'contact_person_name': address.contactName,
        'contact_person_number': address.contactNumber,
        'house': address.house,
        'floor': address.floor,
        'road': address.road,
        'address': safeAddress,
        'additional_information': address.additionalInfo,
        'latitude': address.latitude,
        'longitude': address.longitude,
        'payment_method': paymentMethod,
        'order_amount': orderAmount,
        'order_type': 'delivery',
        'store_id': storeId,
        'zone_id': [zoneId],                  // array, e.g. [2]
        'delivery_charge': deliveryCharge,
        'discount_amount': 0,
        'tax_amount': taxAmount,
        'distance': distance,
        'dm_tips': 0,
        'extra_packaging_amount': 0,
        'is_guest': 0,
        'guest_id': '',
        'is_buy_now': 0,
        'partial_payment': false,
        'schedule_at': null,
        'unavailable_item_note': null,
        'create_new_user': 0,
        'cutlery': 0,
        'cart': cartJson,                     // JSON-encoded string: backend does json_decode($cart)
      },
      requiresAuth: true,
    );
    if (data is Map<String, dynamic>) return PlacedOrderModel.fromJson(data);
    throw const ApiException('Unexpected order placement response');
  }

  /// Calls the backend's /payment-mobile endpoint to create a Razorpay order
  /// and retrieve checkout parameters.
  ///
  /// [appOrderId]   – The app's internal order ID returned by the order-placement API.
  /// [customerId]   – The logged-in customer's ID.
  /// [amountInPaise]– Order total in paise (optional; backend may already know the amount).
  Future<RazorpayOrderDetails> initiatePayment({
    required int appOrderId,
    required int customerId,
    int amountInPaise = 0,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final uri = Uri.parse(ApiConstants.paymentMobile).replace(
      queryParameters: {
        'order_id': appOrderId.toString(),
        'customer_id': customerId.toString(),
        'payment_platform': 'app',
        'callback':
            'https://www.worldofrice.in/profile?page=my-orders',
        'payment_method': 'online',
      },
    );

    debugPrint('[PaymentRepo] initiatePayment → $uri');

    final response = await http
        .get(uri, headers: ApiConstants.authHeaders(token))
        .timeout(const Duration(seconds: 15));

    debugPrint('[PaymentRepo] status: ${response.statusCode}');

    if (response.statusCode != 200) {
      throw Exception(
          'Payment initiation failed (${response.statusCode}): ${response.body}');
    }

    final Map<String, dynamic> data =
        jsonDecode(response.body) as Map<String, dynamic>;

    return RazorpayOrderDetails.fromJson(data, appOrderId);
  }

  /// Calls the backend's /razorpay/redirect endpoint after a successful
  /// Razorpay payment to confirm the order on the server.
  Future<void> confirmPayment({
    required int appOrderId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    final uri = Uri.parse(ApiConstants.razorpayRedirect).replace(
      queryParameters: {
        'order_id': appOrderId.toString(),
        'razorpay_order_id': razorpayOrderId,
        'razorpay_payment_id': razorpayPaymentId,
        'razorpay_signature': razorpaySignature,
      },
    );

    debugPrint('[PaymentRepo] confirmPayment → $uri');

    final response = await http
        .get(uri, headers: ApiConstants.authHeaders(token))
        .timeout(const Duration(seconds: 15));

    debugPrint('[PaymentRepo] confirm status: ${response.statusCode}');

    if (response.statusCode != 200) {
      // Log but don't hard-fail; the payment already succeeded on Razorpay's side.
      debugPrint(
          '[PaymentRepo] confirmPayment non-200 (non-fatal): ${response.body}');
    }
  }
}
