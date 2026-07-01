import 'package:flutter/foundation.dart';

import '../../../../core/network/api_constants.dart';
import '../../../../core/services/api_service.dart';
import '../models/checkout_summary.dart';

class CheckoutRepository {
  CheckoutRepository({ApiService? service}) : _service = service ?? ApiService();

  final ApiService _service;

  /// Calls GET /api/v1/config/get-zone-id and returns the distance in km.
  Future<double> fetchDistanceKm(double lat, double lng) async {
    debugPrint('[CheckoutRepo] fetchDistanceKm lat=$lat lng=$lng');
    final data = await _service.get(
      ApiConstants.getZoneId,
      params: {'lat': '$lat', 'lng': '$lng'},
    );
    if (data is Map) {
      return (data['distance_in_km'] as num?)?.toDouble() ?? 0.0;
    }
    return 0.0;
  }

  /// Delivery charge slabs (₹):
  /// 0–3 km → ₹0 · 3–7 km → ₹50 · 7–10 km → ₹100
  /// 10–15 km → ₹150 · >15 km → ₹150 + ₹10/km (rounded up)
  static double deliveryCharge(double km) {
    if (km <= 3) return 0;
    if (km <= 7) return 50;
    if (km <= 10) return 100;
    if (km <= 15) return 150;
    return 150.0 + (km - 15).ceil() * 10.0;
  }

  /// 5% tax when total cart weight < 25 kg, otherwise ₹0.
  static double tax(double subtotal, double totalWeightKg) {
    return totalWeightKg < 25 ? (subtotal * 5 / 100) : 0;
  }

  CheckoutSummary buildSummary({
    required double subtotal,
    required double totalWeightKg,
    required double distanceInKm,
    double discount = 0,
  }) =>
      CheckoutSummary(
        subtotal: subtotal,
        totalWeightKg: totalWeightKg,
        distanceInKm: distanceInKm,
        deliveryCharge: deliveryCharge(distanceInKm),
        tax: tax(subtotal, totalWeightKg),
        discount: discount,
      );
}
