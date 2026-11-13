import 'package:flutter/material.dart';
import 'router/app_router.dart';
import 'services/api_client.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Muat token tersimpan sebelum router membaca isLoggedIn (guard redirect).
  await ApiClient.instance.getToken();
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
