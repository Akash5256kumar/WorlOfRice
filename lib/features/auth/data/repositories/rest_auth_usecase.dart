import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/api_constants.dart';
import '../../domain/usecases/auth_usecase.dart';
import '../models/login_response.dart';

/// REST implementation of [AuthUseCase] using the World of Rice API.
final class RestAuthUseCase implements AuthUseCase {
  RestAuthUseCase({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _tokenKey = 'auth_token';
  static const _guestIdKey = 'guest_id';

  // ── Public helpers ──────────────────────────────────────────────────────────

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // ── AuthUseCase ─────────────────────────────────────────────────────────────

  @override
  Future<void> login({
    required String emailOrPhone,
    required String password,
  }) async {
    final guestId = await _getOrCreateGuestId();
    final fieldType = emailOrPhone.contains('@') ? 'email' : 'phone';

    final response = await _post(ApiConstants.login, {
      'email_or_phone': emailOrPhone,
      'password': password,
      'login_type': 'manual',
      'field_type': fieldType,
      'type': fieldType,
      'guest_id': guestId,
      'tandc': true,
    });

    final body = _decodeBody(response.body);

    // Non-2xx or explicit error in a 200 response.
    if (_isErrorResponse(response.statusCode, body)) {
      throw AuthException(_friendlyLoginMessage(body, emailOrPhone));
    }

    final loginResponse = LoginResponse.fromJson(body);
    if (loginResponse.token.isEmpty) {
      throw AuthException(_friendlyLoginMessage(body, emailOrPhone));
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, loginResponse.token);
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String confirmPassword,
    required String phone,
    String? fullName,
  }) async {
    final guestId = await _getOrCreateGuestId();

    final response = await _post(ApiConstants.signUp, {
      'name': fullName ?? '',
      'email': email,
      'phone': phone,
      'password': password,
      'confirm_password': confirmPassword,
      'guest_id': guestId,
      'ref_code': '',
    });

    final body = _decodeBody(response.body);

    // Non-2xx or explicit error in a 200 response.
    if (_isErrorResponse(response.statusCode, body)) {
      throw AuthException(_friendlySignUpMessage(body));
    }
  }

  @override
  Future<void> googleSignIn() async {
    throw const AuthException('Google Sign-In is not yet supported.');
  }

  @override
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  Future<http.Response> _post(String url, Map<String, dynamic> body) async {
    try {
      return await _client.post(
        Uri.parse(url),
        headers: ApiConstants.headers,
        body: jsonEncode(body),
      );
    } catch (_) {
      throw const AuthException(
          'Network error. Please check your connection.');
    }
  }

  /// Safely decodes the response body to a JSON map.
  /// Returns an empty map on any parse failure.
  static Map<String, dynamic> _decodeBody(String responseBody) {
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return {};
  }

  /// Returns true when the response should be treated as a failure.
  ///
  /// Handles two common API patterns:
  /// - Standard HTTP error codes (4xx / 5xx).
  /// - HTTP 200 with an `errors` block or an explicit `false`/`"0"` status
  ///   field (common in 6market-based APIs).
  static bool _isErrorResponse(int statusCode, Map<String, dynamic> body) {
    if (statusCode < 200 || statusCode >= 300) return true;

    // HTTP 200 but the body signals failure.
    final errors = body['errors'];
    if (errors is Map && errors.isNotEmpty) return true;
    if (errors is List && errors.isNotEmpty) return true;

    final status = body['status'];
    if (status == false || status == 0 || status == 'error' ||
        status == '0' || status == 'false') {
      return true;
    }

    if (body['success'] == false || body['success'] == 0) return true;

    return false;
  }

  // ── Friendly error messages ─────────────────────────────────────────────────

  /// Produces a user-facing sign-up error.
  ///
  /// Serialises the entire response to a single lowercase string so that the
  /// pattern matching works regardless of nesting depth or field names.
  static String _friendlySignUpMessage(Map<String, dynamic> data) {
    // Flatten everything — field names, values, messages — into one string.
    final flat = jsonEncode(data).toLowerCase();

    if (_containsEmailDuplicate(flat)) {
      return 'This email address is already registered.';
    }
    if (_containsPhoneDuplicate(flat)) {
      return 'This phone number is already registered.';
    }

    // Try to surface a human-readable top-level message if available.
    final msg = _safeTopMessage(data);
    if (msg != null) return msg;

    return 'Registration failed. Please check your details and try again.';
  }

  /// Produces a user-facing login error.
  static String _friendlyLoginMessage(
    Map<String, dynamic> data,
    String emailOrPhone,
  ) {
    final flat = jsonEncode(data).toLowerCase();
    final isEmail = emailOrPhone.contains('@');

    if (_containsCredentialError(flat)) {
      return isEmail
          ? 'Invalid email or password. Please try again.'
          : 'Invalid phone number or password. Please try again.';
    }

    if (_containsNotFoundError(flat)) {
      return 'No account found with these details. Please sign up first.';
    }

    final msg = _safeTopMessage(data);
    if (msg != null) return msg;

    return 'Login failed. Please check your credentials and try again.';
  }

  // ── Pattern helpers ─────────────────────────────────────────────────────────

  static bool _containsEmailDuplicate(String flat) =>
      flat.contains('email') &&
      (flat.contains('taken') ||
          flat.contains('already') ||
          flat.contains('exists') ||
          flat.contains('registered') ||
          flat.contains('duplicate') ||
          flat.contains('used'));

  static bool _containsPhoneDuplicate(String flat) =>
      (flat.contains('phone') || flat.contains('mobile')) &&
      (flat.contains('taken') ||
          flat.contains('already') ||
          flat.contains('exists') ||
          flat.contains('registered') ||
          flat.contains('duplicate') ||
          flat.contains('used'));

  static bool _containsCredentialError(String flat) =>
      flat.contains('credentials') ||
      flat.contains('not match') ||
      flat.contains('wrong password') ||
      flat.contains('invalid password') ||
      flat.contains('incorrect') ||
      flat.contains('unauthorized') ||
      flat.contains('401');

  static bool _containsNotFoundError(String flat) =>
      flat.contains('not found') ||
      flat.contains('no user') ||
      flat.contains('does not exist') ||
      flat.contains('not registered') ||
      flat.contains('no account');

  /// Returns the top-level `message` or `error` string only if it looks like
  /// plain human-readable text (i.e., does not start with `{` or `[`).
  static String? _safeTopMessage(Map<String, dynamic> data) {
    for (final key in ['message', 'error', 'msg']) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) {
        final trimmed = value.trim();
        // Reject raw JSON strings — they start with `{` or `[`.
        if (!trimmed.startsWith('{') && !trimmed.startsWith('[')) {
          return trimmed;
        }
      }
    }
    return null;
  }

  // ── Guest ID ────────────────────────────────────────────────────────────────

  Future<String> _getOrCreateGuestId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_guestIdKey);
    if (existing != null) return existing;
    final id = (Random().nextInt(9000) + 1000).toString();
    await prefs.setString(_guestIdKey, id);
    return id;
  }
}
