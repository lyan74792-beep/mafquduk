// User's own reports screen with Lost, Found, and Emergencies tabs (AppRoutes.myReports).
import 'package:flutter/material.dart';

import '../../core/l10n/l10n.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/item_card.dart';
import '../../core/widgets/status_chip.dart';
import '../../data/models/item_summary.dart';
import '../../data/models/report.dart';
import '../../data/repositories/report_repository.dart';
import 'cancel_report_sheet.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  final _repo = ReportRepository();

  Future<void> _openCancelSheet(
    BuildContext context,
    int reportId,
    Future<void> Function() reload,
  ) async {
    final cancelled = await showCancelReportSheet(context, reportId);
    if (cancelled == true && mounted) {
      await reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(t('reportsMyReportsTitle')),
          bottom: TabBar(
            labelColor: AppColors.govGreen,
            unselectedLabelColor: AppColors.muted,
            indicatorColor: AppColors.govGoldBronze,
            tabs: [
              Tab(text: t('reportsTabLost')),
              Tab(text: t('reportsTabFound')),
              Tab(text: t('reportsTabEmergencies')),
            ],
          ),
        ),
        body: AsyncView<MyReports>(
          load: _repo.myReports,
          builder: (context, data, reload) {
            return TabBarView(
              children: [
                _LostReportsTab(
                  items: data.lost,
                  onReload: reload,
                  onCancel: (id) => _openCancelSheet(context, id, reload),
                ),
                _FoundReportsTab(
                  items: data.found,
                  onReload: reload,
                ),
                _EmergencyReportsTab(
                  items: data.emergencies,
                  onReload: reload,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LostReportsTab extends StatelessWidget {
  const _LostReportsTab({
    required this.items,
    required this.onReload,
    required this.onCancel,
  });

  final List<ItemSummary> items;
  final Future<void> Function() onReload;
  final ValueChanged<int> onCancel;

  bool _canCancel(String status) => status == 'searching' || status == 'matched';

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: onReload,
        child: ListView(
          children: [
            const SizedBox(height: 80),
            MessageView(icon: Icons.inbox_outlined, text: t('emptyList')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onReload,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final canCancel = _canCancel(item.status);
          final hasCancelReason =
              item.cancelReason != null && item.cancelReason!.trim().isNotEmpty;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ItemCard(
                item: item,
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.itemDetails,
                  arguments: item,
                ),
              ),
              if (canCancel)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => onCancel(item.id),
                      icon: const Icon(Icons.cancel_outlined, size: 16),
                      label: Text(t('reportsCancelReportAction')),
                    ),
                  ),
                ),
              if (hasCancelReason)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.dangerSoft,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: AppColors.danger),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${t('reportsCancelReasonPrefix')}: ${tv(item.cancelReason!)}',
                          style: const TextStyle(
                            color: AppColors.danger,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _FoundReportsTab extends StatelessWidget {
  const _FoundReportsTab({
    required this.items,
    required this.onReload,
  });

  final List<ItemSummary> items;
  final Future<void> Function() onReload;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: onReload,
        child: ListView(
          children: [
            const SizedBox(height: 80),
            MessageView(icon: Icons.inbox_outlined, text: t('emptyList')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onReload,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return ItemCard(
            item: item,
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.itemDetails,
              arguments: item,
            ),
          );
        },
      ),
    );
  }
}

class _EmergencyReportsTab extends StatelessWidget {
  const _EmergencyReportsTab({
    required this.items,
    required this.onReload,
  });

  final List<EmergencySummary> items;
  final Future<void> Function() onReload;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: onReload,
        child: ListView(
          children: [
            const SizedBox(height: 80),
            MessageView(icon: Icons.inbox_outlined, text: t('emptyList')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onReload,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final e = items[index];
          final displayName = e.personName ?? t('reportsUnnamedPerson');
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.crisis_alert_outlined, color: AppColors.danger, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$displayName (#${e.id})',
                          style: const TextStyle(
                            color: AppColors.textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      StatusChip(status: e.status, label: e.statusLabel),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${t('reportsAgePrefix')}: ${e.approxAge} · '
                    '${t('reportsLastSeenPrefix')}: ${e.lastSeenLocation}',
                    style: const TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                  if (e.createdAt.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.muted),
                        const SizedBox(width: 4),
                        Text(
                          e.createdAt,
                          style: const TextStyle(color: AppColors.muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
