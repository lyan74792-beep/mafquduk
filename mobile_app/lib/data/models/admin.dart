// Admin dashboard statistics, emergencies, reports, open items, claims, and pending admin models.
import 'item_summary.dart';

class NamedCount {
  const NamedCount({required this.name, required this.count});

  final String name;
  final int count;

  factory NamedCount.fromJson(Map<String, dynamic> j) => NamedCount(
        name: '${j['name'] ?? ''}',
        count: (j['count'] as num?)?.toInt() ?? 0,
      );
}

class HeatPoint {
  const HeatPoint({required this.lat, required this.lng, required this.weight});

  final double lat;
  final double lng;
  final int weight;

  factory HeatPoint.fromJson(Map<String, dynamic> j) => HeatPoint(
        lat: (j['lat'] as num?)?.toDouble() ?? 0,
        lng: (j['lng'] as num?)?.toDouble() ?? 0,
        weight: (j['weight'] as num?)?.toInt() ?? 1,
      );
}

class AdminStats {
  const AdminStats({
    required this.totalLost,
    required this.totalFound,
    required this.pendingMatches,
    required this.claimsUnderReview,
    required this.activeEmergencies,
    required this.avgReviewHours,
    required this.byCategory,
    required this.topLocations,
    required this.heatPoints,
  });

  final int totalLost;
  final int totalFound;
  final int pendingMatches;
  final int claimsUnderReview;
  final int activeEmergencies;
  final double avgReviewHours;
  final List<NamedCount> byCategory;
  final List<NamedCount> topLocations;
  final List<HeatPoint> heatPoints;

  factory AdminStats.fromJson(Map<String, dynamic> j) {
    List<NamedCount> parseCounts(Object? raw) => raw is List
        ? raw
            .whereType<Map>()
            .map((e) => NamedCount.fromJson(e.cast<String, dynamic>()))
            .toList(growable: false)
        : const <NamedCount>[];

    final rawHeat = j['heat_points'];
    final heat = rawHeat is List
        ? rawHeat
            .whereType<Map>()
            .map((e) => HeatPoint.fromJson(e.cast<String, dynamic>()))
            .toList(growable: false)
        : const <HeatPoint>[];

    return AdminStats(
      totalLost: (j['total_lost'] as num?)?.toInt() ?? 0,
      totalFound: (j['total_found'] as num?)?.toInt() ?? 0,
      pendingMatches: (j['pending_matches'] as num?)?.toInt() ?? 0,
      claimsUnderReview: (j['claims_under_review'] as num?)?.toInt() ?? 0,
      activeEmergencies: (j['active_emergencies'] as num?)?.toInt() ?? 0,
      avgReviewHours: (j['avg_review_hours'] as num?)?.toDouble() ?? 0,
      byCategory: parseCounts(j['by_category']),
      topLocations: parseCounts(j['top_locations']),
      heatPoints: heat,
    );
  }
}

class AdminEmergency {
  const AdminEmergency({
    required this.id,
    this.personName,
    required this.approxAge,
    required this.lastSeenLocation,
    required this.clothingDescription,
    required this.reporterPhone,
    this.photoUrl,
    required this.status,
    required this.statusLabel,
    required this.createdAt,
  });

  final int id;
  final String? personName;
  final String approxAge;
  final String lastSeenLocation;
  final String clothingDescription;
  final String reporterPhone;
  final String? photoUrl;
  final String status;
  final String statusLabel;
  final String createdAt;

  bool get isActive => status == 'active';

  factory AdminEmergency.fromJson(Map<String, dynamic> j) {
    final name = j['person_name'] as String?;
    return AdminEmergency(
      id: (j['id'] as num?)?.toInt() ?? 0,
      personName: (name != null && name.trim().isNotEmpty) ? name : null,
      approxAge: '${j['approx_age'] ?? ''}',
      lastSeenLocation: '${j['last_seen_location'] ?? ''}',
      clothingDescription: '${j['clothing_description'] ?? ''}',
      reporterPhone: '${j['reporter_phone'] ?? ''}',
      photoUrl: j['photo_url'] as String?,
      status: '${j['status'] ?? ''}',
      statusLabel: '${j['status_label'] ?? j['status'] ?? ''}',
      createdAt: '${j['created_at'] ?? ''}',
    );
  }
}

class AdminReport {
  const AdminReport({
    required this.item,
    required this.reporterName,
    required this.reporterPhone,
    required this.reporterEmail,
  });

  final ItemSummary item;
  final String reporterName;
  final String reporterPhone;
  final String reporterEmail;

  int get id => item.id;
  String get type => item.type;
  bool get isFound => item.isFound;
  String get itemName => item.itemName;
  String get description => item.description;
  String get category => item.category;
  String get location => item.location;
  double? get lat => item.lat;
  double? get lng => item.lng;
  String? get date => item.date;
  String get status => item.status;
  String get statusLabel => item.statusLabel;
  String? get imageUrl => item.imageUrl;
  String? get reportKind => item.reportKind;
  String? get currentStatus => item.currentStatus;

  factory AdminReport.fromJson(Map<String, dynamic> j) {
    final reporter = j['reporter'] is Map
        ? (j['reporter'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    return AdminReport(
      item: ItemSummary.fromJson(j),
      reporterName: '${reporter['full_name'] ?? ''}',
      reporterPhone: '${reporter['phone'] ?? ''}',
      reporterEmail: '${reporter['email'] ?? ''}',
    );
  }
}

class OpenItems {
  const OpenItems({required this.lost, required this.found});

  final List<ItemSummary> lost;
  final List<ItemSummary> found;

  factory OpenItems.fromJson(Map<String, dynamic> j) {
    List<ItemSummary> parse(Object? raw) => raw is List
        ? raw
            .whereType<Map>()
            .map((e) => ItemSummary.fromJson(e.cast<String, dynamic>()))
            .toList(growable: false)
        : const <ItemSummary>[];

    return OpenItems(
      lost: parse(j['lost']),
      found: parse(j['found']),
    );
  }
}

class AdminClaim {
  const AdminClaim({
    required this.claimId,
    required this.status,
    required this.claimDescription,
    required this.claimDate,
    this.securityQuestion,
    this.correctAnswer,
    this.securityAnswer,
    required this.claimantName,
    required this.claimantEmail,
    required this.claimantPhone,
    required this.item,
  });

  final int claimId;
  final String status;
  final String claimDescription;
  final String claimDate;
  final String? securityQuestion;
  final String? correctAnswer;
  final String? securityAnswer;
  final String claimantName;
  final String claimantEmail;
  final String claimantPhone;
  final ItemSummary item;

  /// True when the claimant's answer equals the finder's answer,
  /// ignoring letter case and spaces (shown as a tick/cross to the admin).
  bool get answerMatches {
    String norm(String? v) => (v ?? '').replaceAll(RegExp(r'\s+'), '').toLowerCase();
    final correct = norm(correctAnswer);
    return correct.isNotEmpty && correct == norm(securityAnswer);
  }

  factory AdminClaim.fromJson(Map<String, dynamic> j) {
    final claimant = j['claimant'] is Map
        ? (j['claimant'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final itemMap = j['item'] is Map
        ? (j['item'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final question = j['security_question'] as String?;
    return AdminClaim(
      claimId: (j['claim_id'] as num?)?.toInt() ?? 0,
      status: '${j['status'] ?? ''}',
      claimDescription: '${j['claim_description'] ?? ''}',
      claimDate: '${j['claim_date'] ?? ''}',
      securityQuestion: (question != null && question.trim().isNotEmpty) ? question : null,
      correctAnswer: j['correct_answer'] as String?,
      securityAnswer: j['security_answer'] as String?,
      claimantName: '${claimant['full_name'] ?? ''}',
      claimantEmail: '${claimant['email'] ?? ''}',
      claimantPhone: '${claimant['phone'] ?? ''}',
      item: ItemSummary.fromJson(itemMap),
    );
  }
}

class PendingAdmin {
  const PendingAdmin({
    required this.adminId,
    required this.fullName,
    required this.email,
    required this.createdAt,
  });

  final int adminId;
  final String fullName;
  final String email;
  final String createdAt;

  int get id => adminId;

  factory PendingAdmin.fromJson(Map<String, dynamic> j) => PendingAdmin(
        adminId: (j['admin_id'] as num?)?.toInt() ?? 0,
        fullName: '${j['full_name'] ?? ''}',
        email: '${j['email'] ?? ''}',
        createdAt: '${j['created_at'] ?? ''}',
      );
}
