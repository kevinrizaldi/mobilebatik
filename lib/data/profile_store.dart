import 'package:flutter/foundation.dart';
import '../services/api_client.dart';
import '../services/profile_service.dart';

class ProfileAddress {
  final String id;
  String label;
  String recipient;
  String phone;
  String address;
  String? province;
  int? provinceId;
  String? city;
  int? cityId;
  String? district;
  int? districtId;
  String? postalCode;
  double? latitude;
  double? longitude;
  bool isPrimary;

  ProfileAddress({
    required this.id,
    required this.label,
    required this.recipient,
    required this.phone,
    required this.address,
    this.province,
    this.provinceId,
    this.city,
    this.cityId,
    this.district,
    this.districtId,
    this.postalCode,
    this.latitude,
    this.longitude,
    this.isPrimary = false,
  });

  /// Format alamat lengkap sesuai website Laravel:
  /// Alamat jalan, Kec. [Kecamatan], [Kota], [Provinsi] [Kode Pos]
  String get displayAddress {
    final parts = <String>[];
    if (address.trim().isNotEmpty) {
      parts.add(address.trim());
    }
    if (district != null &&
        district!.trim().isNotEmpty &&
        !address.toLowerCase().contains(district!.toLowerCase())) {
      parts.add('Kec. ${district!.trim()}');
    }
    if (city != null &&
        city!.trim().isNotEmpty &&
        !address.toLowerCase().contains(city!.toLowerCase())) {
      parts.add(city!.trim());
    }
    if (province != null &&
        province!.trim().isNotEmpty &&
        !address.toLowerCase().contains(province!.toLowerCase())) {
      parts.add(province!.trim());
    }
    final combined = parts.join(', ');
    if (postalCode != null &&
        postalCode!.trim().isNotEmpty &&
        !combined.contains(postalCode!.trim())) {
      return '$combined ${postalCode!.trim()}';
    }
    return combined.isNotEmpty ? combined : address;
  }

  /// Ringkasan wilayah: "Provinsi, Kota, Kecamatan, Kode Pos"
  String get regionSummary {
    final parts = <String>[];
    if (province != null && province!.isNotEmpty) parts.add(province!);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (district != null && district!.isNotEmpty) parts.add('Kec. $district');
    if (postalCode != null && postalCode!.isNotEmpty) parts.add(postalCode!);
    return parts.join(', ');
  }
}

class ProfileStore extends ChangeNotifier {
  ProfileStore._();

  static final ProfileStore instance = ProfileStore._();

  String name = 'Budi Santoso';
  String email = 'budi.santoso@email.com';
  String phone = '+62 812-3456-7890';
  DateTime? birthDate = DateTime(1995, 8, 17);
  String gender = 'Laki-laki';
  Uint8List? photoBytes;

  final List<ProfileAddress> addresses = [
    ProfileAddress(
      id: 'home',
      label: 'Rumah',
      recipient: 'Budi Santoso',
      phone: '+62 812-3456-7890',
      address: 'Jl. Melati No. 18, Kebayoran Baru, Jakarta Selatan',
      isPrimary: true,
    ),
    ProfileAddress(
      id: 'office',
      label: 'Kantor',
      recipient: 'Budi Santoso',
      phone: '+62 812-3456-7890',
      address: 'Gedung Batik Nusantara Lt. 4, Jakarta Pusat',
    ),
  ];

  final List<ProfileReview> reviews = [
    ProfileReview(
      product: 'Kain Batik Tulis Motif Truntum',
      date: '30 Jan 2025',
      rating: 5,
      comment: 'Motifnya rapi dan kain terasa nyaman. Pengiriman juga cepat.',
      imageUrl:
          'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=240&q=80',
    ),
    ProfileReview(
      product: 'Kemeja Batik Parang Seling',
      date: '12 Jan 2025',
      rating: 4,
      comment: 'Warna sesuai foto, ukuran pas. Jahitannya terlihat bagus.',
      imageUrl:
          'https://images.unsplash.com/photo-1593032465175-481ac7f401a0?w=240&q=80',
    ),
  ];
  final Set<String> reviewedOrderIds = {};

  void updateProfile({
    required String name,
    required String email,
    required String phone,
    required DateTime? birthDate,
    required String gender,
  }) {
    this.name = name;
    this.email = email;
    this.phone = phone;
    this.birthDate = birthDate;
    this.gender = gender;
    notifyListeners();
  }

  void setFromUserJson(Map<String, dynamic> user) {
    final newName = user['name']?.toString();
    final newEmail = user['email']?.toString();
    final newPhone = user['phone']?.toString();
    if (newName != null && newName.isNotEmpty) name = newName;
    if (newEmail != null && newEmail.isNotEmpty) email = newEmail;
    if (newPhone != null && newPhone.isNotEmpty) phone = newPhone;
    notifyListeners();
  }

  void setPhoto(Uint8List bytes) {
    photoBytes = bytes;
    notifyListeners();
  }

  Future<void> syncAddressesFromServer() async {
    final token = await ApiClient.instance.getToken();
    if (token == null || token.isEmpty) return;

    try {
      final serverList = await ProfileService.instance.fetchAddresses();
      addresses
        ..clear()
        ..addAll(
          serverList.map(
            (raw) => ProfileAddress(
              id: raw['id'].toString(),
              label: raw['label']?.toString() ?? 'Rumah',
              recipient: raw['recipient_name']?.toString() ?? name,
              phone: raw['phone']?.toString() ?? phone,
              address: raw['full_address']?.toString() ?? '',
              province: raw['province']?.toString(),
              provinceId: int.tryParse(raw['province_id']?.toString() ?? ''),
              city: raw['city']?.toString(),
              cityId: int.tryParse(raw['city_id']?.toString() ?? ''),
              district: (raw['district'] ?? raw['kecamatan'])?.toString(),
              districtId: int.tryParse(raw['district_id']?.toString() ?? ''),
              postalCode: raw['postal_code']?.toString(),
              latitude: double.tryParse(raw['latitude']?.toString() ?? ''),
              longitude: double.tryParse(raw['longitude']?.toString() ?? ''),
              isPrimary: raw['is_primary'] == true,
            ),
          ),
        );
      notifyListeners();
    } catch (_) {
      // Pertahankan state alamat terakhir bila gagal sync.
    }
  }

  Future<void> saveAddress(ProfileAddress address) async {
    final index = addresses.indexWhere((item) => item.id == address.id);
    if (index < 0) {
      addresses.add(address);
    } else {
      addresses[index] = address;
    }
    if (address.isPrimary) {
      for (final item in addresses) {
        if (item.id != address.id) item.isPrimary = false;
      }
    }
    notifyListeners();

    final token = await ApiClient.instance.getToken();
    if (token != null && token.isNotEmpty) {
      try {
        final numericId = int.tryParse(address.id);
        if (index >= 0 && numericId != null) {
          await ProfileService.instance.updateAddress(
            numericId,
            label: address.label,
            recipientName: address.recipient,
            phone: address.phone,
            fullAddress: address.address,
            province: address.province,
            provinceId: address.provinceId,
            city: address.city,
            cityId: address.cityId,
            district: address.district,
            districtId: address.districtId,
            postalCode: address.postalCode,
            latitude: address.latitude,
            longitude: address.longitude,
            isPrimary: address.isPrimary,
          );
        } else {
          await ProfileService.instance.createAddress(
            label: address.label,
            recipientName: address.recipient,
            phone: address.phone,
            fullAddress: address.address,
            province: address.province,
            provinceId: address.provinceId,
            city: address.city,
            cityId: address.cityId,
            district: address.district,
            districtId: address.districtId,
            postalCode: address.postalCode,
            latitude: address.latitude,
            longitude: address.longitude,
            isPrimary: address.isPrimary,
          );
        }
        await syncAddressesFromServer();
      } catch (_) {}
    }
  }

  Future<void> setPrimaryAddress(String id) async {
    for (final item in addresses) {
      item.isPrimary = (item.id == id);
    }
    notifyListeners();

    final token = await ApiClient.instance.getToken();
    final numericId = int.tryParse(id);
    if (token != null && token.isNotEmpty && numericId != null) {
      try {
        await ProfileService.instance.updateAddress(numericId, isPrimary: true);
      } catch (_) {}
    }
  }

  Future<void> removeAddress(String id) async {
    addresses.removeWhere((address) => address.id == id);
    if (addresses.isNotEmpty &&
        !addresses.any((address) => address.isPrimary)) {
      addresses.first.isPrimary = true;
    }
    notifyListeners();

    final token = await ApiClient.instance.getToken();
    final numericId = int.tryParse(id);
    if (token != null && token.isNotEmpty && numericId != null) {
      try {
        await ProfileService.instance.deleteAddress(numericId);
        await syncAddressesFromServer();
      } catch (_) {}
    }
  }

  void addReview(ProfileReview review) {
    reviews.insert(0, review);
    reviewedOrderIds.add(review.orderId);
    notifyListeners();
  }
}

class ProfileReview {
  final String product;
  final String date;
  final int rating;
  final String comment;
  final String imageUrl;
  final String orderId;
  final List<String> tags;
  final List<Uint8List> photos;

  const ProfileReview({
    required this.product,
    required this.date,
    required this.rating,
    required this.comment,
    required this.imageUrl,
    this.orderId = '',
    this.tags = const [],
    this.photos = const [],
  });
}
