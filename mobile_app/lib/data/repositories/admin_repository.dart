// Repository for all admin dashboard endpoints (/admin/*).
import '../../core/network/api_client.dart';
import '../models/admin.dart';
import '../models/shipping.dart';

class AdminRepository {
  AdminRepository({ApiClient? api}) : _api = api ?? ApiClient.instance;

  final ApiClient _api;

  /// Loads dashboard statistics and heatmap points via GET /admin/stats.
  Future<AdminStats> stats() async {
    final data = await _api.get('admin/stats');
    return AdminStats.fromJson(data);
  }

  /// Lists emergency reports filtered by [status] ('active', 'found', 'all') via GET /admin/emergencies.
  Future<List<AdminEmergency>> emergencies({String status = 'active'}) async {
    final data = await _api.get('admin/emergencies', query: {'status': status});
    final raw = data['emergencies'];
    if (raw is! List) return const <AdminEmergency>[];
    return raw
        .whereType<Map>()
        .map((e) => AdminEmergency.fromJson(e.cast<String, dynamic>()))
        .toList(growable: false);
  }

  /// Marks an emergency report as resolved ('found') via POST /admin/emergencies/{id}/resolve.
  Future<void> resolveEmergency(int id) async {
    await _api.post('admin/emergencies/$id/resolve');
  }

  /// Lists reports with reporter contact info via GET /admin/reports.
  Future<List<AdminReport>> reports({String type = 'all', String status = ''}) async {
    final data = await _api.get('admin/reports', query: {'type': type, 'status': status});
    final raw = data['reports'];
    if (raw is! List) return const <AdminReport>[];
    return raw
        .whereType<Map>()
        .map((e) => AdminReport.fromJson(e.cast<String, dynamic>()))
        .toList(growable: false);
  }

  /// Fetches open lost and found items eligible for manual matching via GET /admin/open-items.
  Future<OpenItems> openItems() async {
    final data = await _api.get('admin/open-items');
    return OpenItems.fromJson(data);
  }

  /// Creates a manual match between a lost and found item via POST /admin/matches.
  Future<int> createMatch(int lostId, int foundId) async {
    final data = await _api.post(
      'admin/matches',
      body: {'lost_item_id': lostId, 'found_item_id': foundId},
    );
    return (data['match_id'] as num?)?.toInt() ?? 0;
  }

  /// Lists claims filtered by [status] via GET /admin/claims.
  Future<List<AdminClaim>> claims({String status = 'Under Review'}) async {
    final data = await _api.get('admin/claims', query: {'status': status});
    final raw = data['claims'];
    if (raw is! List) return const <AdminClaim>[];
    return raw
        .whereType<Map>()
        .map((e) => AdminClaim.fromJson(e.cast<String, dynamic>()))
        .toList(growable: false);
  }

  /// Approves a claim via POST /admin/claims/{id}/approve.
  Future<void> approveClaim(int id) async {
    await _api.post('admin/claims/$id/approve');
  }

  /// Rejects a claim with an optional [reason] via POST /admin/claims/{id}/reject.
  Future<void> rejectClaim(int id, {String reason = ''}) async {
    await _api.post(
      'admin/claims/$id/reject',
      body: {if (reason.trim().isNotEmpty) 'reason': reason.trim()},
    );
  }

  /// Marks an approved claim as delivered via POST /admin/claims/{id}/deliver.
  Future<void> deliverClaim(int id) async {
    await _api.post('admin/claims/$id/deliver');
  }

  /// Lists postal shipping requests via GET /admin/shipping.
  Future<List<ShippingRequest>> shipping({String status = ''}) async {
    final data = await _api.get('admin/shipping', query: {'status': status});
    final raw = data['requests'];
    if (raw is! List) return const <ShippingRequest>[];
    return raw
        .whereType<Map>()
        .map((e) => ShippingRequest.fromJson(e.cast<String, dynamic>()))
        .toList(growable: false);
  }

  /// Updates a shipping request's status and tracking details via POST /admin/shipping/{id}.
  Future<void> updateShipping(
    int id, {
    required String status,
    String carrier = '',
    String trackingNumber = '',
    String adminNote = '',
  }) async {
    await _api.post(
      'admin/shipping/$id',
      body: {
        'status': status,
        'carrier': carrier.trim(),
        'tracking_number': trackingNumber.trim(),
        'admin_note': adminNote.trim(),
      },
    );
  }

  /// Lists pending admin accounts awaiting approval via GET /admin/admins/pending.
  Future<List<PendingAdmin>> pendingAdmins() async {
    final data = await _api.get('admin/admins/pending');
    final raw = data['admins'];
    if (raw is! List) return const <PendingAdmin>[];
    return raw
        .whereType<Map>()
        .map((e) => PendingAdmin.fromJson(e.cast<String, dynamic>()))
        .toList(growable: false);
  }

  /// Approves a pending admin account via POST /admin/admins/{id}/approve.
  Future<void> approveAdmin(int id) async {
    await _api.post('admin/admins/$id/approve');
  }

  /// Rejects and deletes a pending admin account via POST /admin/admins/{id}/reject.
  Future<void> rejectAdmin(int id) async {
    await _api.post('admin/admins/$id/reject');
  }
}
