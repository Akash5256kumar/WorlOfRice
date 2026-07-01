import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/api_constants.dart';
import '../../../../core/services/api_service.dart';
import '../models/address_model.dart';
import '../models/customer_model.dart';

/// Fetches customer profile and manages saved addresses.
final class CustomerRepository {
  CustomerRepository({ApiService? service}) : _service = service ?? ApiService();

  final ApiService _service;

  static const _guestIdKey = 'guest_id';

  Future<String?> _guestId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_guestIdKey);
  }

  /// Returns the logged-in customer's profile.
  ///
  /// Confirmed response shape (2026-05-25):
  /// { id, f_name, l_name, phone, email, image, image_full_url,
  ///   wallet_balance, loyalty_point, ref_code, zone_id, ... }
  Future<CustomerModel> getCustomerInfo() async {
    final data = await _service.get(ApiConstants.customerInfo, requiresAuth: true);
    if (data is Map<String, dynamic>) return CustomerModel.fromJson(data);
    throw const ApiException('Unexpected customer info response');
  }

  /// Returns the logged-in customer's saved addresses.
  ///
  /// Confirmed response shape: { addresses: [...], total_size: int, limit, offset }
  /// NOT a plain array — must extract the `addresses` key.
  Future<List<AddressModel>> getAddresses() async {
    final data = await _service.get(ApiConstants.addressList, requiresAuth: true);
    List<dynamic>? list;
    if (data is Map<String, dynamic>) {
      list = data['addresses'] as List<dynamic>?;
    } else if (data is List) {
      list = data;
    }
    if (list == null) return [];
    return list.whereType<Map<String, dynamic>>().map(AddressModel.fromJson).toList();
  }

  /// Saves a new address.
  Future<void> addAddress(AddressModel address) async {
    final guestId = await _guestId();
    await _service.post(
      ApiConstants.addressAdd,
      address.toAddBody(guestId: guestId),
      requiresAuth: true,
    );
  }

  /// Updates an existing address via PUT /address/update/{id}.
  Future<void> updateAddress(int id, AddressModel address) async {
    await _service.put(
      '${ApiConstants.addressUpdate}/$id',
      address.toUpdateBody(),
      requiresAuth: true,
    );
  }

  /// Invalidates the session token on the server (best-effort).
  Future<void> logout() async {
    try {
      await _service.post(ApiConstants.logout, {}, requiresAuth: true);
    } catch (_) {
      // Non-fatal — token is cleared locally regardless.
    }
  }

  /// Returns zone IDs matching the given [lat]/[lng].
  ///
  /// Confirmed response: { zones: [...], zone_id: "[2]", zone_data: [...] }
  Future<String?> getZoneId(double lat, double lng) async {
    final data = await _service.get(
      ApiConstants.getZoneId,
      params: {'lat': lat.toString(), 'lng': lng.toString()},
    );
    if (data is Map<String, dynamic>) return data['zone_id'] as String?;
    return null;
  }
}
