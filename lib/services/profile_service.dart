import '../data/profile_store.dart';
import 'api_client.dart';

class ProfileService {
  ProfileService._();

  static final ProfileService instance = ProfileService._();

  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
    String? phone,
  }) async {
    final res = await ApiClient.instance.patch(
      '/user',
      body: {
        'name': name.trim(),
        'email': email.trim(),
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      },
    );

    final data = res['data'] is Map<String, dynamic>
        ? res['data'] as Map<String, dynamic>
        : null;
    final user = data?['user'] ?? res['user'];
    if (user is Map<String, dynamic>) {
      ProfileStore.instance.setFromUserJson(user);
    }

    return res;
  }

  Future<List<Map<String, dynamic>>> fetchAddresses() async {
    final res = await ApiClient.instance.get('/addresses');
    final data = res['data'];
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> createAddress({
    required String label,
    required String recipientName,
    required String phone,
    required String fullAddress,
    bool isPrimary = false,
  }) async {
    final res = await ApiClient.instance.post(
      '/addresses',
      body: {
        'label': label.trim(),
        'recipient_name': recipientName.trim(),
        'phone': phone.trim(),
        'full_address': fullAddress.trim(),
        'is_primary': isPrimary,
      },
    );
    return (res['data'] as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> updateAddress(
    int id, {
    String? label,
    String? recipientName,
    String? phone,
    String? fullAddress,
    bool? isPrimary,
  }) async {
    final res = await ApiClient.instance.patch(
      '/addresses/$id',
      body: {
        'label': ?label,
        'recipient_name': ?recipientName,
        'phone': ?phone,
        'full_address': ?fullAddress,
        'is_primary': ?isPrimary,
      },
    );
    return (res['data'] as Map<String, dynamic>?) ?? {};
  }

  Future<void> deleteAddress(int id) async {
    await ApiClient.instance.delete('/addresses/$id');
  }
}
