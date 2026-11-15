// Repository for creating and listing postal shipping requests (/shipping, /shipping/mine).
import '../../core/network/api_client.dart';
import '../models/shipping.dart';

class ShippingRepository {
  ShippingRepository({ApiClient? api}) : _api = api ?? ApiClient.instance;

  final ApiClient _api;

  /// Requests postal delivery for an approved claim via POST /shipping.
  Future<int> create({
    required int claimId,
    required String city,
    required String address,
    required String phone,
    String notes = '',
  }) async {
    final data = await _api.post(
      'shipping',
      body: {
        'claim_id': claimId,
        'city': city.trim(),
        'address': address.trim(),
        'phone': phone.trim(),
        if (notes.trim().isNotEmpty) 'notes': notes.trim(),
      },
    );
    return (data['shipping_id'] as num?)?.toInt() ?? 0;
  }

  /// Lists the user's shipping requests via GET /shipping/mine.
  Future<List<ShippingRequest>> mine() async {
    final data = await _api.get('shipping/mine');
    final raw = data['requests'];
    if (raw is! List) return const <ShippingRequest>[];
    return raw
        .whereType<Map>()
        .map((e) => ShippingRequest.fromJson(e.cast<String, dynamic>()))
        .toList(growable: false);
  }
}
