// Repository for lost, found, and emergency reports, report cancellation, and public tracking.
import '../../core/network/api_client.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/picked_image.dart';
import '../models/report.dart';

class ReportRepository {
  ReportRepository({ApiClient? api}) : _api = api ?? ApiClient.instance;

  final ApiClient _api;

  /// Submits a lost item report via POST /reports/lost (multipart).
  Future<CreatedReport> createLost({
    required String category,
    required String landmark,
    String landmarkOther = '',
    double? lat,
    double? lng,
    required DateTime date,
    required String description,
    required String phone,
    PickedImage? image,
  }) async {
    final fields = <String, String>{
      'item_category': category,
      'lost_location': landmark,
      if (landmarkOther.trim().isNotEmpty) 'lost_location_other': landmarkOther.trim(),
      if (lat != null) 'lost_lat': '$lat',
      if (lng != null) 'lost_lng': '$lng',
      'lost_date': formatDate(date),
      'item_description': description.trim(),
      'reporter_phone': phone.trim(),
    };
    final data = await _api.multipart(
      'reports/lost',
      fields: fields,
      files: [if (image != null) image.toUpload('image')],
    );
    return CreatedReport.fromJson(data);
  }

  /// Submits a found item or sighting report via POST /reports/found (multipart).
  Future<CreatedReport> createFound({
    required String category,
    required String landmark,
    String landmarkOther = '',
    double? lat,
    double? lng,
    required DateTime date,
    required String currentStatus,
    required String description,
    required String phone,
    bool sighting = false,
    String securityQuestion = '',
    String securityAnswer = '',
    PickedImage? image,
  }) async {
    final fields = <String, String>{
      'item_category': category,
      'found_location': landmark,
      if (landmarkOther.trim().isNotEmpty) 'found_location_other': landmarkOther.trim(),
      if (lat != null) 'found_lat': '$lat',
      if (lng != null) 'found_lng': '$lng',
      'found_date': formatDate(date),
      'current_status': currentStatus,
      'item_description': description.trim(),
      'finder_phone': phone.trim(),
      'report_kind': sighting ? 'sighting' : 'found',
      if (securityQuestion.trim().isNotEmpty) 'security_question': securityQuestion.trim(),
      if (securityAnswer.trim().isNotEmpty) 'security_answer': securityAnswer.trim(),
    };
    final data = await _api.multipart(
      'reports/found',
      fields: fields,
      files: [if (image != null) image.toUpload('image')],
    );
    return CreatedReport.fromJson(data);
  }

  /// Submits an urgent missing person report via POST /emergencies (multipart).
  Future<int> createEmergency({
    String personName = '',
    required String approxAge,
    required String lastSeenLocation,
    String locationOther = '',
    required String clothing,
    required String phone,
    PickedImage? photo,
  }) async {
    final fields = <String, String>{
      if (personName.trim().isNotEmpty) 'person_name': personName.trim(),
      'approx_age': approxAge.trim(),
      'last_seen_location': lastSeenLocation,
      if (locationOther.trim().isNotEmpty) 'location_other': locationOther.trim(),
      'clothing_description': clothing.trim(),
      'reporter_phone': phone.trim(),
    };
    final data = await _api.multipart(
      'emergencies',
      fields: fields,
      files: [if (photo != null) photo.toUpload('photo')],
    );
    return (data['id'] as num?)?.toInt() ?? 0;
  }

  /// Returns the logged-in user's lost, found, and emergency reports via GET /reports/mine.
  Future<MyReports> myReports() async {
    final data = await _api.get('reports/mine');
    return MyReports.fromJson(data);
  }

  /// Cancels an active lost report via POST /reports/lost/{id}/cancel.
  Future<void> cancelLost(
    int id, {
    required String reason,
    String details = '',
  }) async {
    await _api.post(
      'reports/lost/$id/cancel',
      body: {
        'reason': reason,
        if (details.trim().isNotEmpty) 'details': details.trim(),
      },
    );
  }

  /// Public tracking of a lost item report by ID via GET /track/{id}.
  Future<TrackResult> track(int id) async {
    final data = await _api.get('track/$id');
    return TrackResult.fromJson(data);
  }
}
