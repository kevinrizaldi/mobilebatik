import 'api_client.dart';

class ShippingService {
  ShippingService._();

  static final ShippingService instance = ShippingService._();

  Future<List<Map<String, dynamic>>> fetchProvinces() async {
    try {
      final res = await ApiClient.instance.get('/rajaongkir/provinces', auth: false);
      final list = res['provinces'];
      if (list is List) {
        return list.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
      }
    } catch (_) {}
    return const [
      {'province_id': 10, 'province': 'DKI Jakarta'},
      {'province_id': 5, 'province': 'Jawa Barat'},
      {'province_id': 12, 'province': 'Jawa Tengah'},
      {'province_id': 19, 'province': 'DI Yogyakarta'},
      {'province_id': 18, 'province': 'Jawa Timur'},
      {'province_id': 11, 'province': 'Banten'},
      {'province_id': 1, 'province': 'Bali'},
    ];
  }

  Future<List<Map<String, dynamic>>> fetchCities({int? provinceId}) async {
    try {
      final path = provinceId != null
          ? '/rajaongkir/cities?province_id=$provinceId'
          : '/rajaongkir/cities';
      final res = await ApiClient.instance.get(path, auth: false);
      final list = res['cities'];
      if (list is List) {
        return list.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
      }
    } catch (_) {}
    return const [];
  }

  Future<List<Map<String, dynamic>>> fetchDistricts(int cityId) async {
    try {
      final res = await ApiClient.instance.get('/rajaongkir/districts?city_id=$cityId', auth: false);
      final list = res['districts'];
      if (list is List) {
        return list.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
      }
    } catch (_) {}
    return const [];
  }

  Future<Map<String, dynamic>> fetchPostalCodes({
    String? districtName,
    String? cityName,
    int? cityId,
  }) async {
    try {
      final queryParams = <String>[];
      if (districtName != null && districtName.isNotEmpty) {
        queryParams.add('district_name=${Uri.encodeComponent(districtName)}');
      }
      if (cityName != null && cityName.isNotEmpty) {
        queryParams.add('city_name=${Uri.encodeComponent(cityName)}');
      }
      if (cityId != null) {
        queryParams.add('city_id=$cityId');
      }
      final path = queryParams.isNotEmpty
          ? '/rajaongkir/postal-codes?${queryParams.join('&')}'
          : '/rajaongkir/postal-codes';
      return await ApiClient.instance.get(path, auth: false);
    } catch (_) {
      return const {};
    }
  }

  Future<List<Map<String, dynamic>>> fetchCosts({
    required int addressId,
    required int weightGrams,
    String couriers = 'jne,sicepat,jnt,pos,tiki',
  }) async {
    final res = await ApiClient.instance.post(
      '/shipping/costs',
      body: {
        'address_id': addressId,
        'weight': weightGrams,
        'couriers': couriers,
      },
    );

    final services = res['services'];
    if (services is! List) return const [];

    return services.whereType<Map>().map((raw) {
      final code = (raw['code'] ?? '').toString().toUpperCase();
      final service = (raw['service'] ?? '').toString();
      return <String, dynamic>{
        'name': service.isEmpty ? code : '$code $service',
        'estimate': (raw['etd'] ?? '').toString(),
        'fee': raw['cost'] ?? 0,
      };
    }).toList();
  }
}
