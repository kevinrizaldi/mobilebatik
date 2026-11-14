import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../data/profile_store.dart';
import 'api_client.dart';
import 'api_config.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  Future<void>? _googleInitFuture;

  Future<void> _ensureGoogleInitialized() {
    return _googleInitFuture ??= _googleSignIn.initialize(
      serverClientId: ApiConfig.googleServerClientId,
    );
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await ApiClient.instance.post(
      '/login',
      auth: false,
      body: {'email': email.trim(), 'password': password},
    );

    final data = res['data'] is Map<String, dynamic>
        ? res['data'] as Map<String, dynamic>
        : null;

    final token = (data?['token'] ?? res['token'])?.toString();
    if (token != null && token.isNotEmpty) {
      await ApiClient.instance.setToken(token);
    }

    final user = data?['user'] ?? res['user'];
    if (user is Map<String, dynamic>) {
      ProfileStore.instance.setFromUserJson(user);
    }

    return res;
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    String? phone,
    required String password,
    required String passwordConfirmation,
  }) async {
    final res = await ApiClient.instance.post(
      '/register',
      auth: false,
      body: {
        'name': name.trim(),
        'email': email.trim(),
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );

    final data = res['data'] is Map<String, dynamic>
        ? res['data'] as Map<String, dynamic>
        : null;

    final token = (data?['token'] ?? res['token'])?.toString();
    if (token != null && token.isNotEmpty) {
      await ApiClient.instance.setToken(token);
    }

    final user = data?['user'] ?? res['user'];
    if (user is Map<String, dynamic>) {
      ProfileStore.instance.setFromUserJson(user);
    }

    return res;
  }

  Future<Map<String, dynamic>> loginWithGoogle() async {
    await _ensureGoogleInitialized();

    final GoogleSignInAccount googleUser;
    try {
      googleUser = await _googleSignIn.authenticate(
        scopeHint: ['email', 'profile'],
      );
    } on GoogleSignInException catch (e) {
      debugPrint(
        'GoogleSignInException: code=${e.code.name} '
        'description=${e.description ?? '-'}',
      );
      throw ApiException(
        e.code == GoogleSignInExceptionCode.canceled
            ? 'Login dengan Google dibatalkan.'
            : 'Gagal memulai login dengan Google. ${e.description ?? ''}'
                  .trim(),
      );
    } catch (e) {
      debugPrint('GoogleSignIn unexpected: ${e.runtimeType}: $e');
      throw ApiException(
        'Gagal memulai login dengan Google. Silakan coba lagi.',
      );
    }

    final String? idToken = googleUser.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw ApiException('Token Google tidak tersedia. Silakan coba lagi.');
    }

    final res = await ApiClient.instance.post(
      '/auth/google',
      auth: false,
      body: {'id_token': idToken},
    );

    final data = res['data'] is Map<String, dynamic>
        ? res['data'] as Map<String, dynamic>
        : null;

    final token = (data?['token'] ?? res['token'])?.toString();
    if (token != null && token.isNotEmpty) {
      await ApiClient.instance.setToken(token);
    }

    final user = data?['user'] ?? res['user'];
    if (user is Map<String, dynamic>) {
      ProfileStore.instance.setFromUserJson(user);
    }

    return res;
  }

  Future<Map<String, dynamic>?> fetchCurrentUser() async {
    final token = await ApiClient.instance.getToken();
    if (token == null || token.isEmpty) return null;

    final res = await ApiClient.instance.get('/me');
    final data = res['data'] is Map<String, dynamic>
        ? res['data'] as Map<String, dynamic>
        : null;
    final user = data?['user'] ?? res['user'];
    if (user is Map<String, dynamic>) {
      ProfileStore.instance.setFromUserJson(user);
      return user;
    }
    return null;
  }

  /// Validasi sesi tersimpan saat startup (design doc 2026-11-13):
  /// token valid → profil terisi user asli, tetap login;
  /// token dicabut server (401) → ApiClient sudah menghapus token, router
  /// membuka /home (mode tamu); error koneksi → token dipertahankan, tetap login.
  Future<void> restoreSession() async {
    final token = await ApiClient.instance.getToken();
    if (token == null || token.isEmpty) return;
    try {
      await fetchCurrentUser();
    } on ApiException {
      // 401: token sudah dibersihkan di ApiClient._send;
      // error koneksi lain: token tetap tersimpan.
    }
  }

  Future<void> logout() async {
    try {
      final token = await ApiClient.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await ApiClient.instance.post('/logout');
      }
    } catch (_) {
      // Tetap hapus token lokal meskipun request logout gagal.
    } finally {
      await ApiClient.instance.setToken(null);
    }
  }
}
