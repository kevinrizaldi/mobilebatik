import 'package:flutter/material.dart';
import 'router/app_router.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Muat token tersimpan lalu validasi (GET /me) sebelum router membaca
  // isLoggedIn: sesi mati → /login, sesi hidup → /home, server mati → /home.
  await ApiClient.instance.getToken();
  await AuthService.instance.restoreSession();
  runApp(const MobileBatikAuthApp());
}

class MobileBatikAuthApp extends StatelessWidget {
  const MobileBatikAuthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Hamzah Style Official - Auth',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
    );
  }
}
