/// Product variation (size + price + stock).
///
/// Used in both product listings and cart operations.
/// Shape: { "type": "1KG", "price": 95, "stock": 39, "actual_price": 95, "discount_percentage": 0 }
class VariationModel {
  const VariationModel({
    required this.type,
    required this.price,
    required this.stock,
    this.actualPrice,
    this.discountPercentage = 0.0,
  });

  final String type;

  /// Discounted / selling price.
  final double price;
  final int stock;

  /// Original price before discount. Equals [price] when no discount.
  final double? actualPrice;

  /// Discount percentage (0–100). 0 means no discount.
  final double discountPercentage;

  bool get inStock => stock > 0;

  bool get hasDiscount =>
      discountPercentage > 0 &&
      actualPrice != null &&
      actualPrice! > price;

  /// Amount saved = actualPrice - price (0 when no discount).
  double get savings => hasDiscount ? (actualPrice! - price) : 0.0;

  /// Weight in kilograms parsed from the variation type string.
  /// "1KG" → 1.0, "5KG" → 5.0, "25KG" → 25.0, "500G" → 0.5
  /// Returns 0.0 when the type does not encode a weight.
  double get weightInKg {
    final t = type.toUpperCase().trim();
    final kg = RegExp(r'^(\d+(?:\.\d+)?)\s*KG$').firstMatch(t);
    if (kg != null) return double.parse(kg.group(1)!);
    final g = RegExp(r'^(\d+(?:\.\d+)?)\s*G$').firstMatch(t);
    if (g != null) return double.parse(g.group(1)!) / 1000;
    return 0.0;
  }

  factory VariationModel.fromJson(Map<String, dynamic> json) {
    return VariationModel(
      type: json['type'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      stock: json['stock'] as int? ?? 0,
      actualPrice: (json['actual_price'] as num?)?.toDouble(),
      discountPercentage:
          (json['discount_percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        // Send price as int when it's a whole number to match the web app's
        // format (e.g. 95, not 95.0).
        'price': price == price.truncateToDouble() ? price.toInt() : price,
        'stock': stock,
        if (actualPrice != null) 'actual_price': actualPrice,
        'discount_percentage': discountPercentage,
      };
}
