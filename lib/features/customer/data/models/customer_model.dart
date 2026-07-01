/// Maps `GET /api/v1/customer/info` response.
///
/// Confirmed field names from live response (2026-05-25):
/// { id, f_name, l_name, phone, email, image, image_full_url,
///   is_phone_verified, email_verified_at, status, order_count,
///   wallet_balance, loyalty_point, ref_code, zone_id, ... }
class CustomerModel {
  const CustomerModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.imageFullUrl,
    required this.zoneId,
    required this.walletBalance,
    required this.loyaltyPoints,
    required this.orderCount,
    required this.refCode,
    required this.isPhoneVerified,
  });

  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String? imageFullUrl;
  final int? zoneId;
  final double walletBalance;
  final double loyaltyPoints;
  final int orderCount;
  final String refCode;
  final bool isPhoneVerified;

  String get fullName => '$firstName $lastName'.trim();
  String get initials => firstName.isNotEmpty ? firstName[0].toUpperCase() : '?';

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] as int,
      firstName: json['f_name'] as String? ?? '',
      lastName: json['l_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      imageFullUrl: json['image_full_url'] as String?,
      zoneId: json['zone_id'] as int?,
      walletBalance: (json['wallet_balance'] as num?)?.toDouble() ?? 0.0,
      loyaltyPoints: (json['loyalty_point'] as num?)?.toDouble() ?? 0.0,
      orderCount: json['order_count'] as int? ?? 0,
      refCode: json['ref_code'] as String? ?? '',
      isPhoneVerified: (json['is_phone_verified'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'f_name': firstName,
        'l_name': lastName,
        'email': email,
        'phone': phone,
        'image_full_url': imageFullUrl,
        'zone_id': zoneId,
        'wallet_balance': walletBalance,
        'loyalty_point': loyaltyPoints,
        'order_count': orderCount,
        'ref_code': refCode,
        'is_phone_verified': isPhoneVerified ? 1 : 0,
      };
}
