// Repository for match suggestions and ownership claims (/matches, /items/found/{id}/claim, /claims/mine).
import '../../core/network/api_client.dart';
import '../models/claim.dart';

class ClaimRepository {
  ClaimRepository({ApiClient? api}) : _api = api ?? ApiClient.instance;

  final ApiClient _api;

  /// Lists pending match suggestions for the user via GET /matches.
  Future<List<MatchSuggestion>> matches() async {
    final data = await _api.get('matches');
    final raw = data['matches'];
    if (raw is! List) return const <MatchSuggestion>[];
    return raw
        .whereType<Map>()
        .map((e) => MatchSuggestion.fromJson(e.cast<String, dynamic>()))
        .toList(growable: false);
  }

  /// Submits a claim on a suggested match via POST /matches/{id}/claim.
  Future<int> claimMatch(
    int matchId, {
    required String description,
    String securityAnswer = '',
  }) async {
    final data = await _api.post(
      'matches/$matchId/claim',
      body: {
        'claim_description': description.trim(),
        if (securityAnswer.trim().isNotEmpty) 'security_answer': securityAnswer.trim(),
      },
    );
    return (data['claim_id'] as num?)?.toInt() ?? 0;
  }

  /// Rejects a match suggestion via POST /matches/{id}/reject.
  Future<void> rejectMatch(int matchId) async {
    await _api.post('matches/$matchId/reject');
  }

  /// Submits a direct claim on a found item via POST /items/found/{id}/claim.
  Future<int> claimItem(
    int foundId, {
    required String description,
    String securityAnswer = '',
  }) async {
    final data = await _api.post(
      'items/found/$foundId/claim',
      body: {
        'claim_description': description.trim(),
        if (securityAnswer.trim().isNotEmpty) 'security_answer': securityAnswer.trim(),
      },
    );
    return (data['claim_id'] as num?)?.toInt() ?? 0;
  }

  /// Lists the user's claims via GET /claims/mine.
  Future<List<Claim>> myClaims() async {
    final data = await _api.get('claims/mine');
    final raw = data['claims'];
    if (raw is! List) return const <Claim>[];
    return raw
        .whereType<Map>()
        .map((e) => Claim.fromJson(e.cast<String, dynamic>()))
        .toList(growable: false);
  }
}
