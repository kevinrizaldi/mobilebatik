import 'package:flutter/foundation.dart';

class ApiConfig {
  ApiConfig._();

  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

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

