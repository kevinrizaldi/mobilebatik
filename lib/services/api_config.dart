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
  ///
  /// Mode koneksi:
  /// - **USB (adb reverse):** jalankan `adb reverse tcp:8000 tcp:8000` lalu
  ///   `flutter run` biasa → `localhost:8000` di HP = `localhost:8000` laptop.
  /// - **WiFi / HP fisik:** `flutter run --dart-define=API_BASE_URL=http://<IP_LAPTOP>:8000/api`
  /// - **Android Emulator:** gunakan `--dart-define=API_BASE_URL=http://10.0.2.2:8000/api`
  static String get baseUrl {
    final override = debugBaseUrlOverride;
    if (override != null) return override;
    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl;
    }
    // localhost bekerja untuk:
    // - HP fisik via USB (adb reverse tcp:8000 tcp:8000)
    // - Web / Desktop / iOS Simulator
    // Untuk Android Emulator, gunakan --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
    return 'http://localhost:8000/api';
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
