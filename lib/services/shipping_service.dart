import 'api_client.dart';

class ShippingService {
  ShippingService._();

  static final ShippingService instance = ShippingService._();

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
