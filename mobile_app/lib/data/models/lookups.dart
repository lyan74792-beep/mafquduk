/// Shared lookup lists returned by GET /lookups (categories, landmarks, statuses, reasons).
class Landmark {
  const Landmark({
    required this.name,
    this.lat,
    this.lng,
  });

  final String name;
  final double? lat;
  final double? lng;

  bool get isOther => name == 'أخرى';

  factory Landmark.fromJson(Map<String, dynamic> j) => Landmark(
        name: '${j['name'] ?? ''}',
        lat: (j['lat'] as num?)?.toDouble(),
        lng: (j['lng'] as num?)?.toDouble(),
      );
}

class Lookups {
  const Lookups({
    required this.categories,
    required this.landmarks,
    required this.foundCurrentStatuses,
    required this.cancelReasons,
    required this.otpDevMode,
  });

  final List<String> categories;
  final List<Landmark> landmarks;
  final List<String> foundCurrentStatuses;
  final List<String> cancelReasons;
  final bool otpDevMode;

  factory Lookups.fromJson(Map<String, dynamic> j) {
    List<String> strings(Object? v) =>
        v is List ? v.map((e) => '$e').toList(growable: false) : const <String>[];

    final rawLandmarks = j['landmarks'];
    final landmarks = rawLandmarks is List
        ? rawLandmarks
            .whereType<Map>()
            .map((e) => Landmark.fromJson(e.cast<String, dynamic>()))
            .toList(growable: false)
        : const <Landmark>[];

    return Lookups(
      categories: strings(j['categories']),
      landmarks: landmarks,
      foundCurrentStatuses: strings(j['found_current_statuses']),
      cancelReasons: strings(j['cancel_reasons']),
      otpDevMode: j['otp_dev_mode'] == true,
    );
  }
}
