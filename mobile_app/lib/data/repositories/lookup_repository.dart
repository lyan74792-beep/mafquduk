// Repository for GET /lookups with in-memory static caching after the first successful load.
import '../../core/network/api_client.dart';
import '../models/lookups.dart';

class LookupRepository {
  LookupRepository({ApiClient? api}) : _api = api ?? ApiClient.instance;

  final ApiClient _api;

  static Lookups? _cached;

  static Lookups? get cached => _cached;

  /// Loads shared value lists from GET /lookups and caches the result in memory.
  Future<Lookups> load({bool forceRefresh = false}) async {
    if (!forceRefresh && _cached != null) {
      return _cached!;
    }
    final data = await _api.get('lookups');
    final lookups = Lookups.fromJson(data);
    _cached = lookups;
    return lookups;
  }
}
