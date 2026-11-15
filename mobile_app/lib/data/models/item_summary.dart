/// Lost and found item summary, full item details, and paginated item list models.
class ItemSummary {
  const ItemSummary({
    required this.id,
    required this.type,
    required this.itemName,
    required this.description,
    required this.category,
    required this.location,
    this.lat,
    this.lng,
    this.date,
    required this.status,
    required this.statusLabel,
    this.imageUrl,
    this.reportKind,
    this.currentStatus,
    this.cancelReason,
  });

  final int id;
  final String type;
  final String itemName;
  final String description;
  final String category;
  final String location;
  final double? lat;
  final double? lng;
  final String? date;
  final String status;
  final String statusLabel;
  final String? imageUrl;
  final String? reportKind;
  final String? currentStatus;
  final String? cancelReason;

  bool get isFound => type == 'found';
  bool get isSighting => reportKind == 'sighting';

  factory ItemSummary.fromJson(Map<String, dynamic> j) => ItemSummary(
        id: (j['id'] as num?)?.toInt() ?? 0,
        type: '${j['type'] ?? 'lost'}',
        itemName: '${j['item_name'] ?? ''}',
        description: '${j['description'] ?? ''}',
        category: '${j['category'] ?? ''}',
        location: '${j['location'] ?? ''}',
        lat: (j['lat'] as num?)?.toDouble(),
        lng: (j['lng'] as num?)?.toDouble(),
        date: j['date'] as String?,
        status: '${j['status'] ?? ''}',
        statusLabel: '${j['status_label'] ?? j['status'] ?? ''}',
        imageUrl: j['image_url'] as String?,
        reportKind: j['report_kind'] as String?,
        currentStatus: j['current_status'] as String?,
        cancelReason: j['cancel_reason'] as String?,
      );
}

/// Full details returned by GET /items/{type}/{id}.
class ItemDetails {
  const ItemDetails({
    required this.summary,
    required this.images,
    this.securityQuestion,
  });

  final ItemSummary summary;
  final List<String> images;
  final String? securityQuestion;

  int get id => summary.id;
  String get type => summary.type;
  bool get isFound => summary.isFound;
  bool get isSighting => summary.isSighting;
  String get itemName => summary.itemName;
  String get description => summary.description;
  String get category => summary.category;
  String get location => summary.location;
  double? get lat => summary.lat;
  double? get lng => summary.lng;
  String? get date => summary.date;
  String get status => summary.status;
  String get statusLabel => summary.statusLabel;
  String? get imageUrl => summary.imageUrl;
  String? get reportKind => summary.reportKind;
  String? get currentStatus => summary.currentStatus;

  factory ItemDetails.fromJson(Map<String, dynamic> j) {
    final rawImages = j['images'];
    final images = rawImages is List
        ? rawImages.map((e) => '$e').where((s) => s.isNotEmpty).toList(growable: false)
        : const <String>[];
    final question = j['security_question'] as String?;
    return ItemDetails(
      summary: ItemSummary.fromJson(j),
      images: images,
      securityQuestion: (question != null && question.trim().isNotEmpty) ? question : null,
    );
  }
}

/// Paginated list of items returned by GET /items.
class ItemPage {
  const ItemPage({
    required this.items,
    required this.page,
    required this.hasMore,
  });

  final List<ItemSummary> items;
  final int page;
  final bool hasMore;

  factory ItemPage.fromJson(Map<String, dynamic> j) {
    final raw = j['items'];
    final list = raw is List
        ? raw
            .whereType<Map>()
            .map((e) => ItemSummary.fromJson(e.cast<String, dynamic>()))
            .toList(growable: false)
        : const <ItemSummary>[];
    return ItemPage(
      items: list,
      page: (j['page'] as num?)?.toInt() ?? 1,
      hasMore: j['has_more'] == true,
    );
  }
}
