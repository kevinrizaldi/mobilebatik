import 'package:flutter/foundation.dart';
import '../services/api_client.dart';
import '../services/profile_service.dart';

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

  // User profile fields - initialized empty, populated from server on login
  String name = '';
  String email = '';
  String phone = '';
  DateTime? birthDate;
  String gender = '';
  Uint8List? photoBytes;

  final List<ProfileAddress> addresses = [];
  final List<ProfileReview> reviews = [];
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
    final newBirthDate = user['birth_date']?.toString();
    final newGender = user['gender']?.toString();
    final newPhotoUrl = user['photo_url']?.toString();

    if (newName != null && newName.isNotEmpty) name = newName;
    if (newEmail != null && newEmail.isNotEmpty) email = newEmail;
    if (newPhone != null && newPhone.isNotEmpty) phone = newPhone;
    if (newBirthDate != null && newBirthDate.isNotEmpty) {
      try {
        birthDate = DateTime.parse(newBirthDate);
      } catch (_) {}
    }
    if (newGender != null && newGender.isNotEmpty) gender = newGender;
    // photo_url handled separately via setPhoto if needed
    notifyListeners();
  }

  void clearUserData() {
    name = '';
    email = '';
    phone = '';
    birthDate = null;
    gender = '';
    photoBytes = null;
    addresses.clear();
    reviews.clear();
    reviewedOrderIds.clear();
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
            isPrimary: address.isPrimary,
          );
        } else {
          await ProfileService.instance.createAddress(
            label: address.label,
            recipientName: address.recipient,
            phone: address.phone,
            fullAddress: address.address,
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
  final List<String> photos;

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
