import 'package:flutter/material.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/async_view.dart';
import '../../data/models/notification.dart';
import '../../data/repositories/notification_repository.dart';

/// User notifications list screen using [AsyncView] over [NotificationRepository.list].
/// Unread notifications are shown in bold with a green indicator dot; tapping marks
/// an item read and reloads, and the AppBar provides a "mark all read" action.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _repo = NotificationRepository();
  int _reloadVersion = 0;
  bool _markingAll = false;

  Future<void> _markAllRead() async {
    setState(() => _markingAll = true);
    try {
      await _repo.markAllRead();
      if (!mounted) return;
      setState(() => _reloadVersion++);
    } catch (e) {
      if (!mounted) return;
      showSnack(context, errorText(e), isError: true);
    } finally {
      if (mounted) setState(() => _markingAll = false);
    }
  }

  Future<void> _onTapItem(AppNotification item, Future<void> Function() reload) async {
    if (item.isRead) return;
    try {
      await _repo.markRead(item.id);
      await reload();
    } catch (e) {
      if (!mounted) return;
      showSnack(context, errorText(e), isError: true);
    }
  }

  IconData _iconForType(String? type) {
    switch (type) {
      case 'match':
        return Icons.compare_arrows_rounded;
      case 'claim':
        return Icons.assignment_turned_in_outlined;
      case 'shipping':
        return Icons.local_shipping_outlined;
      case 'emergency':
        return Icons.warning_amber_rounded;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _colorForType(String? type) {
    if (type == 'emergency') return AppColors.danger;
    return AppColors.govGreen;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.govBgLight,
      appBar: AppBar(
        title: Text(t('authNotificationsTitle')),
        actions: [
          TextButton.icon(
            onPressed: _markingAll ? null : _markAllRead,
            icon: const Icon(Icons.done_all_rounded, size: 18, color: AppColors.govGreen),
            label: Text(
              t('authMarkAllRead'),
              style: const TextStyle(
                color: AppColors.govGreen,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
      body: AsyncView<NotificationsPage>(
        key: ValueKey<int>(_reloadVersion),
        load: _repo.list,
        isEmpty: (page) => page.items.isEmpty,
        emptyText: t('authNotificationsEmpty'),
        emptyIcon: Icons.notifications_none_rounded,
        builder: (context, page, reload) {
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: page.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = page.items[index];
              final unread = !item.isRead;
              final iconColor = _colorForType(item.type);

              return Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _onTapItem(item, reload),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.govBgLight,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.borderColor),
                          ),
                          child: Icon(_iconForType(item.type), color: iconColor, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                                        color: AppColors.textColor,
                                      ),
                                    ),
                                  ),
                                  if (unread)
                                    Container(
                                      width: 10,
                                      height: 10,
                                      margin: const EdgeInsets.symmetric(horizontal: 6),
                                      decoration: const BoxDecoration(
                                        color: AppColors.govGreen,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.message,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
                                  color: AppColors.muted,
                                ),
                              ),
                              if (item.createdAt.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  item.createdAt,
                                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
