import 'package:flutter/foundation.dart';

class ApiConfig {
  ApiConfig._();

  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  static const String _envGoogleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  /// Client ID Web OAuth, wajib sama dengan `GOOGLE_CLIENT_ID` backend
  /// (websitebatik) supaya audience id token Google cocok dan
  /// `POST /api/auth/google` tidak 401. Client ID bersifat publik.
  /// Atur via `--dart-define=GOOGLE_SERVER_CLIENT_ID=...` bila berbeda.
  static const String defaultGoogleServerClientId =
      '80665910063-v5jf1546jl545u87vo7bk2pseojlbo0g.apps.googleusercontent.com';

  /// `serverClientId` untuk `GoogleSignIn.initialize`.
  static String get googleServerClientId => _envGoogleServerClientId.isNotEmpty
      ? _envGoogleServerClientId
      : defaultGoogleServerClientId;

  /// Override base URL khusus pengujian (produksi mengatur lewat
  /// `--dart-define=API_BASE_URL=...`). `null` = perilaku normal.
  @visibleForTesting
  static String? debugBaseUrlOverride;

  /// Base URL untuk Laravel API.
  /// - Android Emulator memakai `10.0.2.2` untuk mengarah ke `127.0.0.1` laptop.
  /// - Web / Desktop / iOS Simulator memakai `127.0.0.1`.
  /// - Untuk HP fisik via WiFi, jalankan dengan:
  ///   `flutter run --dart-define=API_BASE_URL=http://<IP_LAPTOP>:8000/api`
  static String get baseUrl {
    final override = debugBaseUrlOverride;
    if (override != null) return override;
    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl;
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api';
    }
    return 'http://127.0.0.1:8000/api';
  }

  /// Format angka menjadi string Rupiah, misal `285000` -> `Rp 285.000`.
  static String formatRupiah(num amount) {
    final intVal = amount.round();
    final str = intVal.abs().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      final posFromEnd = str.length - i;
      if (i > 0 && posFromEnd % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    final prefix = intVal < 0 ? '-Rp ' : 'Rp ';
    return '$prefix$buffer';
  }
}
