// Models for user reports, emergency summaries, report creation results, and public tracking.
import 'item_summary.dart';

class EmergencySummary {
  const EmergencySummary({
    required this.id,
    this.personName,
    required this.approxAge,
    required this.lastSeenLocation,
    required this.status,
    required this.statusLabel,
    required this.createdAt,
  });

  final int id;
  final String? personName;
  final String approxAge;
  final String lastSeenLocation;
  final String status;
  final String statusLabel;
  final String createdAt;

  factory EmergencySummary.fromJson(Map<String, dynamic> j) {
    final name = j['person_name'] as String?;
    return EmergencySummary(
      id: (j['id'] as num?)?.toInt() ?? 0,
      personName: (name != null && name.trim().isNotEmpty) ? name : null,
      approxAge: '${j['approx_age'] ?? ''}',
      lastSeenLocation: '${j['last_seen_location'] ?? ''}',
      status: '${j['status'] ?? ''}',
      statusLabel: '${j['status_label'] ?? j['status'] ?? ''}',
      createdAt: '${j['created_at'] ?? ''}',
    );
  }
}

class MyReports {
  const MyReports({
    required this.lost,
    required this.found,
    required this.emergencies,
  });

  final List<ItemSummary> lost;
  final List<ItemSummary> found;
  final List<EmergencySummary> emergencies;

  bool get isEmpty => lost.isEmpty && found.isEmpty && emergencies.isEmpty;

  factory MyReports.fromJson(Map<String, dynamic> j) {
    List<ItemSummary> parseItems(Object? raw) => raw is List
        ? raw
            .whereType<Map>()
            .map((e) => ItemSummary.fromJson(e.cast<String, dynamic>()))
            .toList(growable: false)
        : const <ItemSummary>[];

    final rawEmergencies = j['emergencies'];
    final emergencies = rawEmergencies is List
        ? rawEmergencies
            .whereType<Map>()
            .map((e) => EmergencySummary.fromJson(e.cast<String, dynamic>()))
            .toList(growable: false)
        : const <EmergencySummary>[];

    return MyReports(
      lost: parseItems(j['lost']),
      found: parseItems(j['found']),
      emergencies: emergencies,
    );
  }
}

class TrackResult {
  const TrackResult({
    required this.id,
    required this.category,
    required this.status,
    required this.statusLabel,
    required this.createdAt,
  });

  final int id;
  final String category;
  final String status;
  final String statusLabel;
  final String createdAt;

  factory TrackResult.fromJson(Map<String, dynamic> j) => TrackResult(
        id: (j['id'] as num?)?.toInt() ?? 0,
        category: '${j['category'] ?? ''}',
        status: '${j['status'] ?? ''}',
        statusLabel: '${j['status_label'] ?? j['status'] ?? ''}',
        createdAt: '${j['created_at'] ?? ''}',
      );
}

class CreatedReport {
  const CreatedReport({
    required this.id,
    required this.matchesFound,
  });

  final int id;
  final int matchesFound;

  factory CreatedReport.fromJson(Map<String, dynamic> j) => CreatedReport(
        id: (j['id'] as num?)?.toInt() ?? 0,
        matchesFound: (j['matches_found'] as num?)?.toInt() ?? 0,
      );
}
