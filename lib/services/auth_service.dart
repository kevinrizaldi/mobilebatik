import '../data/profile_store.dart';
import 'api_client.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await ApiClient.instance.post(
      '/login',
      auth: false,
      body: {
        'email': email.trim(),
        'password': password,
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

