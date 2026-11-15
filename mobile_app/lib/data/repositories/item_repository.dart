// Repository for browsing public items, loading item details, and fetching map pins.
import '../../core/network/api_client.dart';
import '../models/item_summary.dart';

class ItemRepository {
  ItemRepository({ApiClient? api}) : _api = api ?? ApiClient.instance;

  final ApiClient _api;

  /// Paginated browse/search via GET /items.
  Future<ItemPage> browse({
    String type = 'all',
    String category = '',
    String query = '',
    int page = 1,
  }) async {
    final data = await _api.get(
      'items',
      query: {
        'type': type,
        'category': category,
        'q': query.trim(),
        'page': '$page',
      },
    );
    return ItemPage.fromJson(data);
  }

  /// Full item details via GET /items/{type}/{id}.
  Future<ItemDetails> details(String type, int id) async {
    final data = await _api.get('items/$type/$id');
    return ItemDetails.fromJson(data);
  }

  /// Items with non-null coordinates via GET /map/items.
  Future<List<ItemSummary>> mapItems({String type = 'all'}) async {
    final data = await _api.get('map/items', query: {'type': type});
    final raw = data['items'];
    if (raw is! List) return const <ItemSummary>[];
    return raw
        .whereType<Map>()
        .map((e) => ItemSummary.fromJson(e.cast<String, dynamic>()))
        .toList(growable: false);
  }
}
