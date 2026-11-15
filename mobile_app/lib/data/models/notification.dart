/// User notification item and notifications page with unread counter.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    this.type,
    required this.isRead,
    required this.createdAt,
  });

  final int id;
  final String title;
  final String message;
  final String? type;
  final bool isRead;
  final String createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: ((j['notification_id'] ?? j['id']) as num?)?.toInt() ?? 0,
        title: '${j['title'] ?? ''}',
        message: '${j['message'] ?? ''}',
        type: (j['notification_type'] ?? j['type']) as String?,
        isRead: j['is_read'] == true || j['is_read'] == 1,
        createdAt: '${j['created_at'] ?? ''}',
      );
}

class NotificationsPage {
  const NotificationsPage({
    required this.unreadCount,
    required this.items,
  });

  final int unreadCount;
  final List<AppNotification> items;

  factory NotificationsPage.fromJson(Map<String, dynamic> j) {
    final raw = j['notifications'];
    final list = raw is List
        ? raw
            .whereType<Map>()
            .map((e) => AppNotification.fromJson(e.cast<String, dynamic>()))
            .toList(growable: false)
        : const <AppNotification>[];
    return NotificationsPage(
      unreadCount: (j['unread_count'] as num?)?.toInt() ?? 0,
      items: list,
    );
  }
}
