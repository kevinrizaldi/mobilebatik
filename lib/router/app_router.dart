import 'package:go_router/go_router.dart';
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

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
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
        builder: (context, state) => const KatalogScreen(),
      ),
      GoRoute(
        path: '/keranjang',
        name: 'keranjang',
        builder: (context, state) => const KeranjangScreen(),
      ),
      GoRoute(
        path: '/pesanan',
        name: 'pesanan',
        builder: (context, state) => const PesananScreen(),
      ),
      GoRoute(
        path: '/detail-pesanan',
        name: 'detail-pesanan',
        builder: (context, state) => DetailPesananScreen(
          order: state.extra as Map<String, dynamic>? ?? const {},
        ),
      ),
      GoRoute(
        path: '/lacak-pesanan',
        name: 'lacak-pesanan',
        builder: (context, state) => LacakPesananScreen(
          order: state.extra as Map<String, dynamic>? ?? const {},
        ),
      ),
      GoRoute(
        path: '/beri-ulasan',
        name: 'beri-ulasan',
        builder: (context, state) => BeriUlasanScreen(
          order: state.extra as Map<String, dynamic>? ?? const {},
        ),
      ),
      GoRoute(
        path: '/profil',
        name: 'profil',
        builder: (context, state) => const ProfilScreen(),
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
          final extra = state.extra as Map<String, dynamic>?;
          return DetailProdukScreen(product: extra);
        },
      ),
    ],
  );
}
