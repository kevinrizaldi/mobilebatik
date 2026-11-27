import '../data/profile_store.dart';
import 'api_client.dart';

class ProfileService {
  ProfileService._();

  static final ProfileService instance = ProfileService._();

  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
    String? phone,
    String? jenisKelamin,
    String? tanggalLahir,
  }) async {
    final res = await ApiClient.instance.patch(
      '/user',
      body: {
        'name': name.trim(),
        'email': email.trim(),
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        if (jenisKelamin != null && jenisKelamin.trim().isNotEmpty)
          'jenis_kelamin': jenisKelamin.trim(),
        if (tanggalLahir != null && tanggalLahir.trim().isNotEmpty)
          'tanggal_lahir': tanggalLahir.trim(),
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
    String? province,
    int? provinceId,
    String? city,
    int? cityId,
    String? district,
    int? districtId,
    String? postalCode,
    double? latitude,
    double? longitude,
    bool isPrimary = false,
  }) async {
    final body = <String, dynamic>{
      'label': label.trim(),
      'recipient_name': recipientName.trim(),
      'phone': phone.trim(),
      'full_address': fullAddress.trim(),
      'is_primary': isPrimary,
    };
    if (province != null && province.isNotEmpty) body['province'] = province.trim();
    if (provinceId != null) body['province_id'] = provinceId;
    if (city != null && city.isNotEmpty) body['city'] = city.trim();
    if (cityId != null) body['city_id'] = cityId;
    if (district != null && district.isNotEmpty) {
      body['district'] = district.trim();
      body['kecamatan'] = district.trim();
    }
    if (districtId != null) body['district_id'] = districtId;
    if (postalCode != null && postalCode.isNotEmpty) body['postal_code'] = postalCode.trim();
    if (latitude != null) body['latitude'] = latitude;
    if (longitude != null) body['longitude'] = longitude;

    final res = await ApiClient.instance.post('/addresses', body: body);
    return (res['data'] as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> updateAddress(
    int id, {
    String? label,
    String? recipientName,
    String? phone,
    String? fullAddress,
    String? province,
    int? provinceId,
    String? city,
    int? cityId,
    String? district,
    int? districtId,
    String? postalCode,
    double? latitude,
    double? longitude,
    bool? isPrimary,
  }) async {
    final body = <String, dynamic>{
      'label': ?label,
      'recipient_name': ?recipientName,
      'phone': ?phone,
      'full_address': ?fullAddress,
      'is_primary': ?isPrimary,
    };
    if (province != null && province.isNotEmpty) body['province'] = province.trim();
    if (provinceId != null) body['province_id'] = provinceId;
    if (city != null && city.isNotEmpty) body['city'] = city.trim();
    if (cityId != null) body['city_id'] = cityId;
    if (district != null && district.isNotEmpty) {
      body['district'] = district.trim();
      body['kecamatan'] = district.trim();
    }
    if (districtId != null) body['district_id'] = districtId;
    if (postalCode != null && postalCode.isNotEmpty) body['postal_code'] = postalCode.trim();
    if (latitude != null) body['latitude'] = latitude;
    if (longitude != null) body['longitude'] = longitude;

    final res = await ApiClient.instance.patch('/addresses/$id', body: body);
    return (res['data'] as Map<String, dynamic>?) ?? {};
  }

  Future<void> deleteAddress(int id) async {
    await ApiClient.instance.delete('/addresses/$id');
  }
}
