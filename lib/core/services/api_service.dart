import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../network/api_constants.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Central HTTP client. Injects auth token on authenticated requests.
final class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _tokenKey = 'auth_token';

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<Map<String, String>> _buildHeaders({bool requiresAuth = false}) async {
    final base = Map<String, String>.from(ApiConstants.headers);

    if (requiresAuth) {
      final token = await getToken();
      if (token == null) throw const ApiException('Not authenticated', statusCode: 401);
      base['Authorization'] = 'Bearer $token';
    }

    return base;
  }

  static const _timeout = Duration(seconds: 15);

  Future<dynamic> get(
    String url, {
    Map<String, String>? params,
    bool requiresAuth = false,
    // When set, used as-is instead of _buildHeaders — pass {} for no headers.
    Map<String, String>? overrideHeaders,
  }) async {
    final uri = Uri.parse(url).replace(queryParameters: params);
    debugPrint('[API] → GET $uri');
    try {
      final headers = overrideHeaders ?? await _buildHeaders(requiresAuth: requiresAuth);
      debugPrint('[API] headers keys: ${headers.keys.toList()}');
      final response = await _client.get(uri, headers: headers).timeout(_timeout);
      debugPrint('[API] ← ${response.statusCode} GET $uri\n${response.body}');
      return _parse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint('[API] ✗ GET $uri → $e');
      throw ApiException(_networkMessage(e));
    }
  }

  Future<dynamic> delete(
    String url, {
    Map<String, String>? params,
    bool requiresAuth = false,
  }) async {
    final uri = Uri.parse(url).replace(queryParameters: params);
    debugPrint('[API] → DELETE $uri');
    try {
      final response = await _client
          .delete(uri, headers: await _buildHeaders(requiresAuth: requiresAuth))
          .timeout(_timeout);
      debugPrint('[API] ← ${response.statusCode} DELETE $uri\n${response.body}');
      return _parse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint('[API] ✗ DELETE $uri → $e');
      throw ApiException(_networkMessage(e));
    }
  }

  Future<dynamic> post(
    String url,
    Map<String, dynamic> body, {
    bool requiresAuth = false,
  }) async {
    final bodyJson = jsonEncode(body);
    _logLong('[API] → POST $url\n$bodyJson');
    try {
      final response = await _client
          .post(Uri.parse(url),
              headers: await _buildHeaders(requiresAuth: requiresAuth),
              body: bodyJson)
          .timeout(_timeout);
      _logLong('[API] ← ${response.statusCode} POST $url\n${response.body}');
      return _parse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint('[API] ✗ POST $url → $e');
      throw ApiException(_networkMessage(e));
    }
  }

  Future<dynamic> put(
    String url,
    Map<String, dynamic> body, {
    bool requiresAuth = false,
  }) async {
    debugPrint('[API] → PUT $url\n${jsonEncode(body)}');
    try {
      final response = await _client
          .put(Uri.parse(url),
              headers: await _buildHeaders(requiresAuth: requiresAuth),
              body: jsonEncode(body))
          .timeout(_timeout);
      debugPrint('[API] ← ${response.statusCode} PUT $url\n${response.body}');
      return _parse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint('[API] ✗ PUT $url → $e');
      throw ApiException(_networkMessage(e));
    }
  }

  static String _networkMessage(Object e) {
    if (e is SocketException) {
      return 'No internet connection.\nPlease check your network and try again.';
    }
    if (e is TimeoutException) {
      return 'Request timed out.\nYour connection may be slow — please try again.';
    }
    return 'Something went wrong.\nPlease try again.';
  }

  dynamic _parse(http.Response response) {
    dynamic data;
    try {
      data = jsonDecode(response.body);
    } catch (_) {}

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    throw ApiException(_extractMessage(data, response.statusCode), statusCode: response.statusCode);
  }

  String _extractMessage(dynamic data, int statusCode) {
    if (data is Map) {
      if (data['message'] is String) return data['message'] as String;
      if (data['error'] is String) return data['error'] as String;
      if (data['errors'] is List) {
        final first = (data['errors'] as List).firstOrNull;
        if (first is Map && first['message'] is String) return first['message'] as String;
      }
    }
    return 'Request failed (HTTP $statusCode)';
  }

  /// Prints [message] in 800-character chunks so the full content is visible
  /// in the Android logcat / Flutter debug console (debugPrint truncates at ~1020 chars).
  static void _logLong(String message) {
    const chunkSize = 800;
    if (message.length <= chunkSize) {
      debugPrint(message);
      return;
    }
    var offset = 0;
    while (offset < message.length) {
      final end = (offset + chunkSize).clamp(0, message.length);
      debugPrint(message.substring(offset, end));
      offset = end;
    }
  }
}
