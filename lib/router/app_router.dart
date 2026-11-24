import 'package:go_router/go_router.dart';
import '../screens/checkout_screen.dart';
import '../screens/pembayaran_screen.dart';
import '../screens/detail_produk_screen.dart';
import '../screens/beri_ulasan_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/detail_pesanan_screen.dart';
import '../screens/home_screen.dart';
import '../screens/keranjang_screen.dart';
import '../screens/katalog_screen.dart';
import '../screens/lacak_pesanan_screen.dart';
import '../screens/login_screen.dart';
import '../screens/pesanan_screen.dart';
import '../screens/profil_screen.dart';
import '../screens/profil_subscreens.dart';
import '../screens/register_screen.dart';
import '../screens/reset_password_screen.dart';
import '../services/api_client.dart';
import '../widgets/app_back_scope.dart';

class AppRouter {
  /// Rute yang butuh login (Task 12): checkout, pesanan (+ detail/lacak),
  /// profil (+ sub-rute termasuk alamat), pembayaran, beri-ulasan.
  static const List<String> _authRequiredPaths = [
    '/checkout',
    '/pembayaran',
    '/pesanan',
    '/detail-pesanan',
    '/lacak-pesanan',
    '/beri-ulasan',
    '/profil',
  ];

  static const List<String> _authEntryPaths = ['/login', '/register'];

  static bool _requiresAuth(String location) => _authRequiredPaths.any(
    (path) => location == path || location.startsWith('$path/'),
  );

  /// Cast aman untuk `state.extra` (Task 12): bukan Map → null, layar
  /// memakai fallback default-nya masing-masing.
  static Map<String, dynamic>? _extraMap(Object? extra) =>
      extra is Map<String, dynamic> ? extra : null;

  static final GoRouter router = GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final location = state.uri.path;
      final loggedIn = ApiClient.instance.isLoggedIn;

      if (_requiresAuth(location) && !loggedIn) return '/login';
      if (loggedIn && _authEntryPaths.contains(location)) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => AppBackScope(child: const LoginScreen()),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        name: 'reset-password',
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/katalog',
        name: 'katalog',
        builder: (context, state) => AppBackScope(child: const KatalogScreen()),
      ),
      GoRoute(
        path: '/keranjang',
        name: 'keranjang',
        builder: (context, state) =>
            AppBackScope(child: const KeranjangScreen()),
      ),
      GoRoute(
        path: '/checkout',
        name: 'checkout',
        builder: (context, state) =>
            CheckoutScreen(checkoutData: _extraMap(state.extra)),
      ),
      GoRoute(
        path: '/pembayaran',
        name: 'pembayaran',
        builder: (context, state) =>
            PembayaranScreen(paymentData: _extraMap(state.extra)),
      ),
      GoRoute(
        path: '/pesanan',
        name: 'pesanan',
        builder: (context, state) => AppBackScope(child: const PesananScreen()),
      ),
      GoRoute(
        path: '/detail-pesanan',
        name: 'detail-pesanan',
        builder: (context, state) =>
            DetailPesananScreen(order: _extraMap(state.extra) ?? const {}),
      ),
      GoRoute(
        path: '/lacak-pesanan',
        name: 'lacak-pesanan',
        builder: (context, state) =>
            LacakPesananScreen(order: _extraMap(state.extra) ?? const {}),
      ),
      GoRoute(
        path: '/beri-ulasan',
        name: 'beri-ulasan',
        builder: (context, state) =>
            BeriUlasanScreen(order: _extraMap(state.extra) ?? const {}),
      ),
      GoRoute(
        path: '/profil',
        name: 'profil',
        builder: (context, state) => AppBackScope(child: const ProfilScreen()),
      ),
      GoRoute(
        path: '/profil/edit',
        name: 'profil-edit',
        builder: (context, state) => const EditProfilScreen(),
      ),
      GoRoute(
        path: '/profil/data-diri',
        name: 'profil-data-diri',
        builder: (context, state) => const DataDiriScreen(),
      ),
      GoRoute(
        path: '/profil/daftar-alamat',
        name: 'profil-daftar-alamat',
        builder: (context, state) => const DaftarAlamatScreen(),
      ),
      GoRoute(
        path: '/profil/ulasan-saya',
        name: 'profil-ulasan-saya',
        builder: (context, state) => const UlasanSayaScreen(),
      ),
      GoRoute(
        path: '/detail-produk',
        name: 'detail-produk',
        builder: (context, state) {
          final extra = _extraMap(state.extra);
          return DetailProdukScreen(product: extra);
        },
      ),
    ],
  );
}
