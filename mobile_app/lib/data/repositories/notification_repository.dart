// Repository for listing and marking user notifications as read (/notifications).
import '../../core/network/api_client.dart';
import '../models/notification.dart';

class NotificationRepository {
  NotificationRepository({ApiClient? api}) : _api = api ?? ApiClient.instance;

  final ApiClient _api;

  /// Fetches notifications and unread count via GET /notifications.
  Future<NotificationsPage> list() async {
    final data = await _api.get('notifications');
    return NotificationsPage.fromJson(data);
  }

  /// Marks a single notification as read via POST /notifications/{id}/read.
  Future<void> markRead(int id) async {
    await _api.post('notifications/$id/read');
  }

  /// Marks all notifications as read via POST /notifications/read-all.
  Future<void> markAllRead() async {
    await _api.post('notifications/read-all');
  }
}
