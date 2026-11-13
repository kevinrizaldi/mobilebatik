import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();
  static const String _tokenKey = 'sanctum_api_token';
  static const Duration _timeout = Duration(seconds: 12);

  String? _cachedToken;

  /// Status login sinkron untuk guard router.
  /// Token di-priming di `main()` sebelum runApp, sehingga flag ini
  /// sudah mewakili state sesungguhnya saat redirect pertama berjalan.
  bool get isLoggedIn => _cachedToken != null && _cachedToken!.isNotEmpty;

  Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString(_tokenKey);
    return _cachedToken;
  }

  Future<void> setToken(String? token) async {
    _cachedToken = token;
    final prefs = await SharedPreferences.getInstance();
    if (token == null || token.isEmpty) {
      await prefs.remove(_tokenKey);
    } else {
      await prefs.setString(_tokenKey, token);
    }
  }

  Future<Map<String, String>> _buildHeaders({bool auth = true}) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (auth) {
      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Uri _buildUri(String path, [Map<String, String>? query]) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('${ApiConfig.baseUrl}$cleanPath');
    if (query == null || query.isEmpty) return uri;
    return uri.replace(queryParameters: query);
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? query,
    bool auth = true,
  }) async {
    return _send(
      () async => http
          .get(_buildUri(path, query), headers: await _buildHeaders(auth: auth))
          .timeout(_timeout),
    );
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    return _send(
      () async => http
          .post(
            _buildUri(path),
            headers: await _buildHeaders(auth: auth),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeout),
    );
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    return _send(
      () async => http
          .patch(
            _buildUri(path),
            headers: await _buildHeaders(auth: auth),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(_timeout),
    );
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    bool auth = true,
  }) async {
    return _send(
      () async => http
          .delete(_buildUri(path), headers: await _buildHeaders(auth: auth))
          .timeout(_timeout),
    );
  }

  Future<Map<String, dynamic>> _send(
    Future<http.Response> Function() requestFn,
  ) async {
    try {
      final response = await requestFn();
      final decoded = _decodeJson(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decoded;
      }

      if (response.statusCode == 401) {
        await setToken(null);
      }

      final errorMsg = _extractErrorMessage(decoded, response.statusCode);
      throw ApiException(errorMsg, statusCode: response.statusCode);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException(
        'Koneksi ke server Laravel timeout. Pastikan server Laravel aktif.',
      );
    } catch (e) {
      throw ApiException(
        'Tidak dapat terhubung ke server Laravel (${ApiConfig.baseUrl}).',
      );
    }
  }

  Map<String, dynamic> _decodeJson(String body) {
    if (body.trim().isEmpty) return {};
    try {
      final parsed = jsonDecode(body);
      if (parsed is Map<String, dynamic>) return parsed;
      return {'data': parsed};
    } catch (_) {
      return {};
    }
  }

  String _extractErrorMessage(Map<String, dynamic> json, int statusCode) {
    final errors = json['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final firstValue = errors.values.first;
      if (firstValue is List && firstValue.isNotEmpty) {
        return firstValue.first.toString();
      }
      return firstValue.toString();
    }
    if (json['message'] != null && json['message'].toString().isNotEmpty) {
      return json['message'].toString();
    }
    return 'Terjadi kesalahan server (HTTP $statusCode).';
  }
}

