import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/api_constants.dart';
import '../../../../core/services/api_service.dart';
import '../../../home/data/models/variation_model.dart';
import '../models/cart_item_model.dart';

/// Handles cart operations: list, add, update.
///
/// Auth behaviour confirmed from live API (2026-05-25):
/// - cart/add requires `model`, `price`, `guest_id` even when Bearer token is sent.
/// - cart/list returns a plain JSON array (not paginated).
final class CartRepository {
  CartRepository({ApiService? service}) : _service = service ?? ApiService();

  final ApiService _service;

  static const _guestIdKey = 'guest_id';

  Future<String?> _guestId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_guestIdKey);
  }

  Future<bool> get _isLoggedIn async => (await _service.getToken()) != null;

  /// Returns cart items for the current user or guest.
  ///
  /// Response is a plain JSON array: [{ id, item_id, quantity, variation, item }]
  Future<List<CartItemModel>> getCart() async {
    final loggedIn = await _isLoggedIn;
    dynamic data;
    if (loggedIn) {
      data = await _service.get(ApiConstants.cartList, requiresAuth: true);
    } else {
      final guestId = await _guestId();
      data = await _service.get(
        ApiConstants.cartList,
        params: guestId != null ? {'guest_id': guestId} : null,
      );
    }

    // API may return a plain array or a paginated object with a nested list.
    List<dynamic> raw;
    if (data is List) {
      raw = data;
    } else if (data is Map) {
      // Try common envelope keys: data, cart, items, list
      final nested = data['data'] ?? data['cart'] ?? data['items'] ?? data['list'];
      raw = nested is List ? nested : [];
    } else {
      raw = [];
    }

    return raw
        .whereType<Map<String, dynamic>>()
        .map(CartItemModel.fromJson)
        .toList();
  }

  /// Adds an item to the cart.
  ///
  /// Required fields confirmed from live API:
  /// item_id, quantity, variation, add_on_ids, add_on_qtys, guest_id, model, price.
  Future<void> addToCart({
    required int itemId,
    required int quantity,
    required VariationModel variation,
  }) async {
    final loggedIn = await _isLoggedIn;
    final guestId = await _guestId();

    final body = <String, dynamic>{
      'item_id': itemId,
      'quantity': quantity,
      'variation': [variation.toJson()],
      'add_on_ids': <dynamic>[],
      'add_on_qtys': <dynamic>[],
      'model': 'Item',
      'price': variation.price,
    };

    await _service.post(ApiConstants.cartAdd, body, requiresAuth: loggedIn);
  }

  /// Removes a cart entry by [cartId].
  Future<void> removeFromCart({required int cartId}) async {
    final loggedIn = await _isLoggedIn;
    final guestId = await _guestId();
    final params = <String, String>{'cart_id': cartId.toString()};
    if (!loggedIn && guestId != null) params['guest_id'] = guestId;

    await _service.delete(
      ApiConstants.cartRemoveItem,
      params: params,
      requiresAuth: loggedIn,
    );
  }

  /// Updates quantity/variation for an existing cart entry by [cartId].
  Future<void> updateCart({
    required int cartId,
    required int quantity,
    required VariationModel variation,
  }) async {
    final loggedIn = await _isLoggedIn;
    final guestId = await _guestId();

    await _service.post(
      ApiConstants.cartUpdate,
      {
        'cart_id': cartId,
        'quantity': quantity,
        'variation': [variation.toJson()],
        'add_on_ids': <dynamic>[],
        'add_on_qtys': <dynamic>[],
        'model': 'Item',
        'price': variation.price,
       
      },
      requiresAuth: loggedIn,
    );
  }
}
