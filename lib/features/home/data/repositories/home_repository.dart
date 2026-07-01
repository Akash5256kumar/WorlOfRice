import 'dart:developer';

import '../../../../core/network/api_constants.dart';
import '../../../../core/services/api_service.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';

/// Fetches categories and products from the World of Rice API.
final class HomeRepository {
  HomeRepository({ApiService? service}) : _service = service ?? ApiService();

  final ApiService _service;

  /// Fetches all root categories with at least one product.
  ///
  /// Confirmed endpoint: GET /api/v1/categories — returns plain array.
  Future<List<CategoryModel>> getCategories() async {
    log('getCategories: starting', name: 'HomeRepo');
    try {
      final data = await _service.get(ApiConstants.categories);
      log('getCategories: raw type=${data.runtimeType}', name: 'HomeRepo');
      if (data is! List) {
        log('getCategories: unexpected response — not a List', name: 'HomeRepo');
        return [];
      }
      final result = data
          .whereType<Map<String, dynamic>>()
          .map(CategoryModel.fromJson)
          .where((c) => c.isRoot && c.moduleId == ApiConstants.moduleId)
          .toList();
      log('getCategories: parsed ${result.length} root categories', name: 'HomeRepo');
      return result;
    } catch (e, st) {
      log('getCategories: ERROR $e', name: 'HomeRepo', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Fetches trending products from the dedicated trading endpoint.
  Future<List<ProductModel>> getTrendingProducts({
    int offset = 1,
    int limit = 10,
  }) async {
    log('getTrendingProducts: starting', name: 'HomeRepo');
    try {
      final data = await _service.get(
        ApiConstants.trendingItems,
        params: {'offset': offset.toString(), 'limit': limit.toString()},
      );
      if (data is! Map<String, dynamic>) return [];
      final rawProducts = data['products'];
      if (rawProducts is! List) return [];
      final result = rawProducts
          .whereType<Map<String, dynamic>>()
          .map(ProductModel.fromJson)
          .toList();
      log('getTrendingProducts: parsed ${result.length} products', name: 'HomeRepo');
      return result;
    } catch (e, st) {
      log('getTrendingProducts: ERROR $e', name: 'HomeRepo', error: e, stackTrace: st);
      return [];
    }
  }

  /// Fetches paginated products.
  Future<({List<ProductModel> products, int totalSize})> getProducts({
    int offset = 1,
    int limit = 12,
    List<int> categoryIds = const [],
    String name = '',
    double minPrice = 0,
    double maxPrice = 999999,
  }) async {
    // category_ids must be sent as the literal string "[]" when empty, or
    // "[19,20]" when filtered — the server parses this JSON-like string format.
    final categoryIdsValue =
        categoryIds.isEmpty ? '[]' : '[${categoryIds.join(',')}]';

    final params = <String, String>{
      'offset': offset.toString(),
      'limit': limit.toString(),
      'list_type': 'item',
      'data_type': 'category',
      'rating_count': '0',
      'min_price': minPrice.toString(),
      'max_price': maxPrice.toString(),
      'name': name,
      'category_ids': categoryIdsValue,
      'brand_ids': '[]',
      'filter': '[""]',
    };

    log('getProducts: params=$params', name: 'HomeRepo');
    try {
      final data = await _service.get(ApiConstants.combinedData, params: params);
      log('getProducts: raw type=${data.runtimeType}', name: 'HomeRepo');
      if (data is! Map<String, dynamic>) {
        log('getProducts: unexpected response — not a Map', name: 'HomeRepo');
        return (products: <ProductModel>[], totalSize: 0);
      }

      final totalSize = data['total_size'] as int? ?? 0;
      final rawProducts = data['products'];
      final products = <ProductModel>[];
      if (rawProducts is List) {
        for (final p in rawProducts) {
          if (p is Map<String, dynamic>) products.add(ProductModel.fromJson(p));
        }
      }
      log('getProducts: totalSize=$totalSize parsed=${products.length}', name: 'HomeRepo');
      return (products: products, totalSize: totalSize);
    } catch (e, st) {
      log('getProducts: ERROR $e', name: 'HomeRepo', error: e, stackTrace: st);
      return (products: <ProductModel>[], totalSize: 0);
    }
  }
}
