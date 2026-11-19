# mobilebatik — Hamzah Style (Flutter)

Aplikasi mobile marketplace batik **Hamzah Style**: katalog, keranjang, checkout, pembayaran Midtrans Snap, riwayat pesanan, ulasan, dan profil — terhubung ke REST API backend Laravel (`../websitebatik`, dokumentasi [`../websitebatik/docs/api.md`](../websitebatik/docs/api.md)).

## Menjalankan

Prasyarat: Flutter SDK (Dart `^3.11.0`), backend Laravel sudah jalan.

```bash
flutter pub get
flutter run                 # Android emulator / device terdeteksi
```

Base URL API dibaca dari compile-time define `API_BASE_URL` (`lib/services/api_config.dart`):

| Environment | Default tanpa define | Contoh define |
|---|---|---|
| Android emulator | `http://10.0.2.2:8000/api` (→ `127.0.0.1` laptop) | – |
| iOS simulator / web / desktop | `http://127.0.0.1:8000/api` | – |
| HP fisik via Wi-Fi | – | `flutter run --dart-define=API_BASE_URL=http://<IP_LAPTOP>:8000/api` |
| Produksi | – | `flutter run --dart-define=API_BASE_URL=https://<domain>/api` |

Contoh produksi / build APK:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://<domain>/api
```

Catatan: backend produksi wajib HTTPS + CORS sudah diatur; ganti define setiap ganti domain/API.

## Alur demo (untuk video/presentasi)

1. **Mode tamu & Login/Register** — aplikasi langsung membuka `/home` tanpa token: tamu bebas menjelajah beranda, katalog, dan detail produk. Menekan **+ Keranjang** sebagai tamu memunculkan ajakan login (SnackBar aksi "Login" → `/login`). Daftar lewat `/register` (nama, email, telepon, password) atau masuk lewat `/login`; setelah berhasil, kembali ke `/home` dan lanjut belanja — checkout, pesanan, profil, dan ulasan tetap memerlukan login.
2. **Beranda & katalog** — `/home` (banner + produk unggulan) → `/katalog` dengan pencarian, filter kategori, dan sortir harga (`price_asc`/`price_desc`/`latest`).
3. **Detail produk** — gambar, harga, stok per ukuran, rating + ulasan; pilih ukuran → **Tambah ke Keranjang** (stok tidak cukup → pesan error tampil).
4. **Keranjang** (`/keranjang`) — ubah qty, centang item, hapus; subtotal terhitung dari item terpilih.
5. **Checkout** (`/checkout`, butuh login) — isi data pengiriman + ringkasan belanja → buat pesanan (`POST /api/checkout`) → dapat `snap_token` + `snap_redirect_url`.
6. **Pembayaran** (`/pembayaran`) — bayar via Snap Midtrans (VA/QRIS/dll., sandbox) → status berubah setelah webhook diterima backend.
7. **Pesanan** (`/pesanan`) — daftar + status (`Menunggu Pembayaran` → `Diproses` → `Dikirim` → `Selesai`); detail (`/detail-pesanan`), lacak resi (`/lacak-pesanan`), konfirmasi terima, atau batalkan bila belum bayar.
8. **Ulasan** (`/beri-ulasan`) — hanya untuk pesanan berstatus **Selesai**; rating 1–5 + komentar.
9. **Profil & alamat** (`/profil`) — edit profil, kelola alamat (tambah/ubah/utama/hapus), lihat ulasan saya, logout.

Route yang butuh login (guard `lib/router/app_router.dart`): `/checkout`, `/pembayaran`, `/pesanan`, `/detail-pesanan`, `/lacak-pesanan`, `/beri-ulasan`, `/profil`.

## Analisis & test

```bash
flutter analyze        # lint statis (0 error/warning; 18 info pre-existing)
flutter test           # 34 test (api client, cart store, checkout flow, produk, widget)
```

Jalankan subset: `flutter test test/cart_store_test.dart`.

## Arsitektur

```
lib/
  main.dart                 # bootstrap: muat token → MaterialApp.router
  router/app_router.dart    # GoRouter + auth guard (redirect login/home)
  services/
    api_config.dart         # base URL (dart-define) + format Rupiah
    api_client.dart         # HTTP client + Bearer token + parse error
    auth_service.dart       # register/login/logout/me
    product_service.dart    # katalog, detail, kategori
    cart_service.dart       # cart CRUD
    order_service.dart      # checkout, pesanan, payment, confirm/cancel, ulasan
    profile_service.dart    # profil + alamat
  data/                     # state ChangeNotifier: cart_store, profile_store
  screens/                  # layar per fitur (login, katalog, checkout, …)
  widgets/ + theme/ + utils/# komponen bersama, tema, helper responsif
test/                       # unit & widget test
```

Pola: **service** (I/O API) → **store** (`ChangeNotifier` untuk state bersama) → **router** (navigasi + guard), tanpa framework state berat. Kontrak API ganda (`data` wrapper + key legacy) ditangani di service.
