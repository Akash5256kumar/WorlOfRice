/// Response model for POST /customer/order/place
class PlacedOrderModel {
  const PlacedOrderModel({
    required this.orderId,
    required this.message,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.userId,
  });

  final int orderId;
  final String message;
  final double totalAmount;
  final String status;
  final String createdAt;
  final int? userId;

  factory PlacedOrderModel.fromJson(Map<String, dynamic> json) {
    return PlacedOrderModel(
      orderId: _parseInt(json['order_id']),
      message: json['message'] as String? ?? 'Order placed',
      totalAmount: _parseDouble(json['total_ammount'] ?? json['total_amount']),
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] as String? ?? '',
      userId: json['user_id'] as int?,
    );
  }

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}

class RazorpayOrderDetails {
  const RazorpayOrderDetails({
    required this.razorpayOrderId,
    required this.amountInPaise,
    required this.currency,
    required this.keyId,
    required this.appOrderId,
    this.customerName,
    this.customerEmail,
    this.customerPhone,
    this.description,
  });

  /// Razorpay-generated order ID (starts with "order_").
  final String razorpayOrderId;

  /// Amount in smallest currency unit (paise for INR; 100 paise = ₹1).
  final int amountInPaise;

  final String currency;

  /// Razorpay key_id (rzp_test_xxx or rzp_live_xxx).
  final String keyId;

  /// The app's internal order ID (returned by the backend).
  final int appOrderId;

  final String? customerName;
  final String? customerEmail;
  final String? customerPhone;
  final String? description;

  factory RazorpayOrderDetails.fromJson(
      Map<String, dynamic> json, int appOrderId) {
    return RazorpayOrderDetails(
      razorpayOrderId: json['order_id'] as String? ??
          json['razorpay_order_id'] as String? ??
          '',
      amountInPaise: _parseInt(json['amount']),
      currency: json['currency'] as String? ?? 'INR',
      keyId: json['key'] as String? ?? json['key_id'] as String? ?? '',
      appOrderId: appOrderId,
      customerName: json['prefill']?['name'] as String?,
      customerEmail: json['prefill']?['email'] as String?,
      customerPhone: json['prefill']?['contact'] as String?,
      description: json['description'] as String?,
    );
  }

  /// Converts to the map expected by razorpay_flutter's `Razorpay.open()`.
  Map<String, dynamic> toRazorpayOptions() => {
        'key': keyId,
        'amount': amountInPaise,
        'currency': currency,
        'name': 'World of Rice',
        'description': description ?? 'Order #$appOrderId',
        if (razorpayOrderId.isNotEmpty) 'order_id': razorpayOrderId,
        'prefill': {
          'name': customerName ?? '',
          'email': customerEmail ?? '',
          'contact': customerPhone ?? '',
        },
        'theme': {'color': '#2E7D32'},
        'send_sms_hash': true,
        'remember_customer': false,
      };

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}
