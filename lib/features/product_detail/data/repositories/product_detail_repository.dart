export '../../../home/data/models/variation_model.dart' show VariationModel;

import 'package:flutter/foundation.dart';

import '../../../../core/network/api_constants.dart';
import '../../../../core/services/api_service.dart';
import '../../../home/data/models/product_model.dart';

/// Extra fields returned only by `GET /api/v1/items/details/{slug}`.
class ProductDetailModel {
  const ProductDetailModel({
    required this.product,
    required this.tags,
    required this.storeName,
    required this.storeLogoUrl,
    required this.storeAvgRating,
    required this.storeDeliveryTime,
    required this.orderCount,
    required this.maximumCartQuantity,
    this.relatedItems = const [],
  });

  final ProductModel product;
  final List<String> tags;
  final String storeName;
  final String? storeLogoUrl;
  final double storeAvgRating;
  final String storeDeliveryTime;
  final int orderCount;
  final int maximumCartQuantity;
  final List<ProductModel> relatedItems;

  ProductDetailModel copyWith({List<ProductModel>? relatedItems}) =>
      ProductDetailModel(
        product: product,
        tags: tags,
        storeName: storeName,
        storeLogoUrl: storeLogoUrl,
        storeAvgRating: storeAvgRating,
        storeDeliveryTime: storeDeliveryTime,
        orderCount: orderCount,
        maximumCartQuantity: maximumCartQuantity,
        relatedItems: relatedItems ?? this.relatedItems,
      );

  factory ProductDetailModel.fromJson(Map<String, dynamic> json) {
    final product = ProductModel.fromJson(json);

    final rawTags = json['tags'];
    final tags = <String>[];
    if (rawTags is List) {
      for (final t in rawTags) {
        if (t is Map<String, dynamic>) {
          final tag = (t['tag'] as String?)?.trim();
          if (tag != null && tag.isNotEmpty) tags.add(tag);
        }
      }
    }

    final store = json['store_details'];
    String storeName = '';
    String? storeLogoUrl;
    double storeAvgRating = 0;
    String deliveryTime = '20-60 min';
    if (store is Map<String, dynamic>) {
      storeName = store['name'] as String? ?? '';
      storeLogoUrl = store['logo_full_url'] as String?;
      storeAvgRating = (store['avg_rating'] as num?)?.toDouble() ?? 0;
      deliveryTime = store['delivery_time'] as String? ?? deliveryTime;
    }

    return ProductDetailModel(
      product: product,
      tags: tags,
      storeName: storeName,
      storeLogoUrl: storeLogoUrl,
      storeAvgRating: storeAvgRating,
      storeDeliveryTime: deliveryTime,
      orderCount: json['order_count'] as int? ?? 0,
      maximumCartQuantity: json['maximum_cart_quantity'] as int? ?? 5,
    );
  }
}

class ProductDetailRepository {
  ProductDetailRepository({ApiService? service})
      : _service = service ?? ApiService();

  final ApiService _service;

  Future<ProductDetailModel> getDetail(String slug) async {
    debugPrint('[ProductDetailRepo] fetching details for slug: $slug');
    final data = await _service.get('${ApiConstants.itemDetails}/$slug');
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Unexpected response format for item details.');
    }
    return ProductDetailModel.fromJson(data);
  }

  Future<List<ProductModel>> getRelatedItems(int itemId) async {
    debugPrint('[ProductDetailRepo] fetching related items for id: $itemId');
    final data = await _service.get(
      '${ApiConstants.relatedStoreItems}/$itemId',
      params: {'offset': '1', 'limit': '10'},
    );
    if (data is! List) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(ProductModel.fromJson)
        .toList();
  }
}

