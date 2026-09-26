import 'package:flutter/foundation.dart';

class ProfileAddress {
  final String id;
  String label;
  String recipient;
  String phone;
  String address;
  bool isPrimary;

  ProfileAddress({
    required this.id,
    required this.label,
    required this.recipient,
    required this.phone,
    required this.address,
    this.isPrimary = false,
  });
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
          'https://images.unsplash.com/photo-1605806616949-1e87b487cb2a?w=240&q=80',
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

  void setPhoto(Uint8List bytes) {
    photoBytes = bytes;
    notifyListeners();
  }

  void saveAddress(ProfileAddress address) {
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
  }

  void removeAddress(String id) {
    addresses.removeWhere((address) => address.id == id);
    if (addresses.isNotEmpty &&
        !addresses.any((address) => address.isPrimary)) {
      addresses.first.isPrimary = true;
    }
    notifyListeners();
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
