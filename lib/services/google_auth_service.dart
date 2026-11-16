import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'auth_service.dart';

class GoogleAuthService {
  GoogleAuthService._();

  static final GoogleAuthService instance = GoogleAuthService._();

  static const String webClientId =
      '80665910063-v5jf1546jl545u87vo7bk2pseojlbo0g.apps.googleusercontent.com';

  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    try {
      await GoogleSignIn.instance.initialize(
        clientId: kIsWeb ? webClientId : null,
        serverClientId: webClientId,
      );
      _initialized = true;
    } catch (e) {
      debugPrint('GoogleSignIn initialize warning: $e');
    }
  }

  /// Melakukan proses Google Sign-In secara interaktif.
  /// Mengembalikan data respons dari backend `/api/auth/google`,
  /// atau null jika dibatalkan oleh pengguna.
  Future<Map<String, dynamic>?> signIn() async {
    await _ensureInitialized();

    try {
      final account = await GoogleSignIn.instance.authenticate();
      final auth = account.authentication;
      final idToken = auth.idToken;

      return await AuthService.instance.loginWithGoogle(
        idToken: idToken,
        email: account.email,
        name: account.displayName,
        googleId: account.id,
        avatar: account.photoUrl,
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }
      rethrow;
    }
  }
}

