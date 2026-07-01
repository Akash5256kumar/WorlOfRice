import '../../../home/data/models/product_model.dart';
import '../../../home/data/models/variation_model.dart';

/// Maps one item from `GET /api/v1/customer/cart/list`.
///
/// Confirmed field names from live response (2026-05-25):
/// { id, user_id, module_id, item_id, is_guest, add_on_ids, add_on_qtys,
///   item_type, price, quantity, variation: {type, price, stock},
///   created_at, updated_at, item: {...ProductModel} }
class CartItemModel {
  const CartItemModel({
    required this.id,
    required this.itemId,
    required this.userId,
    required this.moduleId,
    required this.isGuest,
    required this.quantity,
    required this.price,
    required this.variation,
    this.product,
  });

  final int id;
  final int itemId;
  final int? userId;
  final int moduleId;
  final bool isGuest;
  final int quantity;

  /// Price of the selected variation at time of adding to cart.
  final double price;
  final VariationModel variation;
  final ProductModel? product;

  double get lineTotal => price * quantity;

  /// Total weight in kg for this line (variation weight × quantity).
  double get weightTotal => variation.weightInKg * quantity;

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    // The cart/list API can return `variation` in two shapes:
    //   • single object  → {"type":"1KG","price":65,"stock":33}
    //   • array          → [{"type":"1KG","price":65,"stock":33}]
    // Handle both so the variation type is never left empty.
    final rawVar = json['variation'];
    VariationModel variation = const VariationModel(type: '', price: 0, stock: 0);
    if (rawVar is Map<String, dynamic>) {
      variation = VariationModel.fromJson(rawVar);
    } else if (rawVar is List && rawVar.isNotEmpty) {
      final first = rawVar.first;
      if (first is Map<String, dynamic>) {
        variation = VariationModel.fromJson(first);
      }
    }

    ProductModel? product;
    final rawItem = json['item'];
    if (rawItem is Map<String, dynamic>) {
      product = ProductModel.fromJson(rawItem);
    }

    return CartItemModel(
      id: json['id'] as int,
      itemId: json['item_id'] as int,
      userId: json['user_id'] as int?,
      moduleId: json['module_id'] as int? ?? 2,
      isGuest: json['is_guest'] as bool? ?? false,
      quantity: json['quantity'] as int? ?? 1,
      price: (json['price'] as num?)?.toDouble() ?? variation.price,
      variation: variation,
      product: product,
    );
  }

  /// Builds the cart item object that goes inside the `cart` JSON string
  /// sent to POST /customer/order/place.
  ///
  /// Shape must match what the web app sends:
  /// { item_id, item_campaign_id, item_type, price, quantity,
  ///   variant, add_on_ids, add_on_qtys, add_ons,
  ///   variation: [{type, price, stock}] }
  Map<String, dynamic> toJson() => {
        'item_id': itemId,
        'item_campaign_id': null,
        'item_type': 'AppModelsItem',
        // Send price as int when it's a whole number to match the web app format.
        'price': price == price.truncateToDouble() ? price.toInt() : price,
        'quantity': quantity,
        'variant': [],
        'add_on_ids': [],
        'add_on_qtys': [],
        'add_ons': [],
        // MUST be a List — backend accesses $c['variation'][0]['type'].
        // Sending as a plain object causes "Undefined array key 0".
        'variation': variation.type.isNotEmpty ? [variation.toJson()] : [],
      };
}
