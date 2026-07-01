import 'package:flutter/foundation.dart';

import '../../../../core/network/api_constants.dart';
import '../../../../core/services/api_service.dart';
import '../models/order_model.dart';

final class OrderRepository {
  OrderRepository({ApiService? service}) : _service = service ?? ApiService();

  final ApiService _service;

  /// Fetches the customer's active/running orders.
  ///
  /// Response: { "orders": [...], "total_size": N }
  Future<({List<OrderModel> orders, int total})> getRunningOrders({
    int limit = 20,
    int offset = 1,
  }) async {
    final data = await _service.get(
      ApiConstants.runningOrders,
      params: {'limit': '$limit', 'offset': '$offset'},
      requiresAuth: true,
    );

    debugPrint('[OrderRepo] running-orders raw: $data');

    List<dynamic>? rawList;
    int total = 0;

    if (data is Map<String, dynamic>) {
      rawList = data['orders'] as List<dynamic>? ??
          data['data'] as List<dynamic>? ??
          data['items'] as List<dynamic>?;
      total = _parseInt(data['total_size'] ?? data['total'] ?? rawList?.length);
    } else if (data is List) {
      rawList = data;
      total = data.length;
    }

    if (rawList == null || rawList.isEmpty) {
      return (orders: <OrderModel>[], total: 0);
    }

    final orders = rawList
        .whereType<Map<String, dynamic>>()
        .map(OrderModel.fromJson)
        .toList();

    return (orders: orders, total: total);
  }

  /// Fetches live tracking data for a single order.
  ///
  /// Response: flat order object or { "order": {...} }
  Future<OrderModel> getOrderTrack(int orderId) async {
    final data = await _service.get(
      ApiConstants.trackOrder,
      params: {'order_id': '$orderId'},
      requiresAuth: true,
    );

    debugPrint('[OrderRepo] track raw: $data');

    if (data is Map<String, dynamic>) {
      final orderJson = _buildTrackOrderPayload(data);
      if (orderJson != null) return OrderModel.fromJson(orderJson);
    }

    throw const ApiException('Unexpected order track response');
  }

  /// Fetches full details for a single order.
  ///
  /// The details endpoint returns a flat array of items:
  ///   [{ "id": 670, "item_id": 42, "order_id": 100299, "item_details": {...},
  ///      "variation": [...], "quantity": 1, "price": 65, "tax_amount": 3 }]
  ///
  /// This method also calls the track endpoint to obtain the order header
  /// (amounts, status, store, address), then merges in the items from details.
  Future<OrderModel> getOrderDetails(int orderId) async {
    // ── 1. Fetch items from the details endpoint (flat array) ──────────────
    final rawDetails = await _service.get(
      ApiConstants.orderDetails,
      params: {'order_id': '$orderId'},
      requiresAuth: true,
    );

    debugPrint('[OrderRepo] details raw: $rawDetails');

    final items = _parseItemsList(rawDetails);

    // ── 2. Fetch order header from the track endpoint ──────────────────────
    try {
      final headerOrder = await getOrderTrack(orderId);
      // Merge: use track data for header fields, items from details endpoint.
      return headerOrder.copyWith(items: items);
    } catch (e) {
      debugPrint('[OrderRepo] track fallback in details: $e');
    }

    // ── 3. Fallback: construct minimal model from items alone ──────────────
    return OrderModel(
      id: orderId,
      orderAmount: 0,
      deliveryCharge: 0,
      couponDiscount: 0,
      taxAmount: 0,
      paymentStatus: '',
      orderStatus: '',
      paymentMethod: '',
      orderType: '',
      createdAt: '',
      minDeliveryTime: 0,
      maxDeliveryTime: 0,
      items: items,
      trackingTimeline: const [],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static List<OrderItem> _parseItemsList(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map(OrderItem.fromJson)
          .toList();
    }
    if (raw is Map<String, dynamic>) {
      // Defensive: some API versions wrap items under a key.
      final list = raw['details'] ?? raw['items'] ?? raw['data'];
      if (list is List) {
        return list
            .whereType<Map<String, dynamic>>()
            .map(OrderItem.fromJson)
            .toList();
      }
    }
    return [];
  }

  static Map<String, dynamic>? _buildTrackOrderPayload(
      Map<String, dynamic> raw) {
    final root = Map<String, dynamic>.from(raw);
    final nestedOrder = _unwrapOrderPayload(raw['order']) ??
        _unwrapOrderPayload(raw['data']) ??
        _unwrapOrderPayload(raw);

    if (nestedOrder == null) return null;

    final merged = Map<String, dynamic>.from(nestedOrder);
    final itemPayload = _extractItemsPayload(root);
    if (itemPayload != null) {
      merged.putIfAbsent('details', () => itemPayload);
    }

    return merged;
  }

  static dynamic _extractItemsPayload(Map<String, dynamic> raw) {
    for (final key in const ['details', 'items', 'order_details']) {
      final value = raw[key];
      if (value is List && value.isNotEmpty) return value;
    }

    final data = raw['data'];
    if (data is Map<String, dynamic>) {
      for (final key in const ['details', 'items', 'order_details']) {
        final value = data[key];
        if (value is List && value.isNotEmpty) return value;
      }
    }

    final order = raw['order'];
    if (order is Map<String, dynamic>) {
      for (final key in const ['details', 'items', 'order_details']) {
        final value = order[key];
        if (value is List && value.isNotEmpty) return value;
      }
    }

    return null;
  }

  static Map<String, dynamic>? _unwrapOrderPayload(dynamic raw) {
    if (raw is! Map<String, dynamic>) return null;

    if (raw.containsKey('id') || raw.containsKey('order_id')) {
      return raw;
    }

    for (final key in const ['order', 'data']) {
      final nested = _unwrapOrderPayload(raw[key]);
      if (nested != null) return nested;
    }

    return null;
  }

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}
