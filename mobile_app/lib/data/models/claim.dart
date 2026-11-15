// Models for automatic/manual match suggestions, user claims, and attached shipping info.
import 'item_summary.dart';

class MatchSuggestion {
  const MatchSuggestion({
    required this.matchId,
    required this.score,
    required this.lostItemId,
    required this.found,
    this.securityQuestion,
  });

  final int matchId;
  final double score;
  final int lostItemId;
  final ItemSummary found;
  final String? securityQuestion;

  factory MatchSuggestion.fromJson(Map<String, dynamic> j) {
    final foundMap = (j['found'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    final question = j['security_question'] as String?;
    return MatchSuggestion(
      matchId: (j['match_id'] as num?)?.toInt() ?? 0,
      score: (j['score'] as num?)?.toDouble() ?? 0,
      lostItemId: (j['lost_item_id'] as num?)?.toInt() ?? 0,
      found: ItemSummary.fromJson(foundMap),
      securityQuestion: (question != null && question.trim().isNotEmpty) ? question : null,
    );
  }
}

class ShippingInfo {
  const ShippingInfo({
    required this.shippingId,
    required this.status,
    required this.statusLabel,
    this.carrier,
    this.trackingNumber,
  });

  final int shippingId;
  final String status;
  final String statusLabel;
  final String? carrier;
  final String? trackingNumber;

  factory ShippingInfo.fromJson(Map<String, dynamic> j) => ShippingInfo(
        shippingId: (j['shipping_id'] as num?)?.toInt() ?? 0,
        status: '${j['status'] ?? ''}',
        statusLabel: '${j['status_label'] ?? j['status'] ?? ''}',
        carrier: j['carrier'] as String?,
        trackingNumber: j['tracking_number'] as String?,
      );
}

class Claim {
  const Claim({
    required this.claimId,
    required this.status,
    required this.statusLabel,
    required this.claimDate,
    this.reviewedAt,
    this.rejectReason,
    required this.item,
    this.shipping,
  });

  final int claimId;
  final String status;
  final String statusLabel;
  final String claimDate;
  final String? reviewedAt;
  final String? rejectReason;
  final ItemSummary item;
  final ShippingInfo? shipping;

  bool get canRequestShipping => status == 'Approved' && shipping == null;

  factory Claim.fromJson(Map<String, dynamic> j) {
    final itemMap = (j['item'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    final shippingRaw = j['shipping'];
    return Claim(
      claimId: (j['claim_id'] as num?)?.toInt() ?? 0,
      status: '${j['status'] ?? ''}',
      statusLabel: '${j['status_label'] ?? j['status'] ?? ''}',
      claimDate: '${j['claim_date'] ?? ''}',
      reviewedAt: j['reviewed_at'] as String?,
      rejectReason: j['reject_reason'] as String?,
      item: ItemSummary.fromJson(itemMap),
      shipping: shippingRaw is Map
          ? ShippingInfo.fromJson(shippingRaw.cast<String, dynamic>())
          : null,
    );
  }
}
