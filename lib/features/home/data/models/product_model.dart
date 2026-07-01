import 'variation_model.dart';

/// Maps a product from `GET /api/v1/get-combined-data` (`products` array)
/// and from `GET /api/v1/customer/cart/list` (`item` nested object).
///
/// Confirmed field names from live cart/list response (2026-05-25).
class ProductModel {
  const ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageFullUrl,
    required this.imagesFullUrl,
    required this.categoryIds,
    required this.basePrice,
    required this.discount,
    required this.discountType,
    required this.avgRating,
    required this.ratingCount,
    required this.variations,
    required this.status,
    required this.storeId,
    required this.zoneId,
    required this.slug,
    required this.totalStock,
    required this.maximumCartQuantity,
    required this.isApproved,
  });

  final int id;
  final String name;
  final String description;
  final String? imageFullUrl;
  final List<String> imagesFullUrl;
  final List<int> categoryIds;

  /// Highest variant price (the "base" price field from API).
  final double basePrice;
  final double discount;
  final String discountType;
  final double avgRating;
  final int ratingCount;
  final List<VariationModel> variations;
  final int status;
  final int storeId;
  final int? zoneId;
  final String slug;
  final int totalStock;
  final int maximumCartQuantity;
  final int isApproved;

  bool get isAvailable => status == 1 && isApproved == 1;

  /// Cheapest in-stock variation price.
  double get minPrice {
    final inStock = variations.where((v) => v.inStock).toList();
    if (inStock.isEmpty && variations.isNotEmpty) return variations.first.price;
    if (inStock.isEmpty) return basePrice;
    return inStock.map((v) => v.price).reduce((a, b) => a < b ? a : b);
  }

  /// First in-stock variation; falls back to first variation.
  VariationModel? get defaultVariation {
    if (variations.isEmpty) return null;
    return variations.firstWhere((v) => v.inStock, orElse: () => variations.first);
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // category_ids: [] or [19, 71]
    final rawCatIds = json['category_ids'];
    final categoryIds = <int>[];
    if (rawCatIds is List) {
      for (final id in rawCatIds) {
        if (id is int) categoryIds.add(id);
        if (id is String) categoryIds.add(int.tryParse(id) ?? 0);
      }
    }

    // variations: [{type, price, stock}]
    final rawVars = json['variations'];
    final variations = <VariationModel>[];
    if (rawVars is List) {
      for (final v in rawVars) {
        if (v is Map<String, dynamic>) variations.add(VariationModel.fromJson(v));
      }
    }

    // images_full_url: [url, url, null]  — filter nulls
    final rawImgs = json['images_full_url'];
    final imagesFullUrl = <String>[];
    if (rawImgs is List) {
      for (final img in rawImgs) {
        if (img is String) imagesFullUrl.add(img);
      }
    }

    return ProductModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageFullUrl: json['image_full_url'] as String?,
      imagesFullUrl: imagesFullUrl,
      categoryIds: categoryIds,
      basePrice: (json['price'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      discountType: json['discount_type'] as String? ?? 'percent',
      avgRating: (json['avg_rating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: json['rating_count'] as int? ?? 0,
      variations: variations,
      status: json['status'] as int? ?? 1,
      storeId: json['store_id'] as int? ?? 0,
      zoneId: json['zone_id'] as int?,
      slug: json['slug'] as String? ?? '',
      totalStock: json['stock'] as int? ?? 0,
      maximumCartQuantity: json['maximum_cart_quantity'] as int? ?? 5,
      isApproved: json['is_approved'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'image_full_url': imageFullUrl,
        'images_full_url': imagesFullUrl,
        'category_ids': categoryIds,
        'price': basePrice,
        'discount': discount,
        'discount_type': discountType,
        'avg_rating': avgRating,
        'rating_count': ratingCount,
        'variations': variations.map((v) => v.toJson()).toList(),
        'status': status,
        'store_id': storeId,
        'zone_id': zoneId,
        'slug': slug,
        'stock': totalStock,
        'maximum_cart_quantity': maximumCartQuantity,
        'is_approved': isApproved,
      };
}
