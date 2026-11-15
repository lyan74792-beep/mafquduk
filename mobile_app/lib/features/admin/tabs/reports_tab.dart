// Reports tab: type filter chips (all/lost/found), report cards with reporter info, and manual match FAB.
import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/item_card.dart';
import '../../../data/models/admin.dart';
import '../../../data/repositories/admin_repository.dart';

class ReportsTab extends StatefulWidget {
  const ReportsTab({super.key});

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  final AdminRepository _repo = AdminRepository();
  String _type = 'all';
  int _refreshSeed = 0;

  Future<void> _openManualMatch() async {
    final matched = await Navigator.pushNamed(
      context,
      AppRoutes.adminManualMatch,
    );
    if (matched == true && mounted) {
      setState(() => _refreshSeed++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filters = <(String, String)>[
      ('all', t('adminReportsFilterAll')),
      ('lost', t('adminReportsFilterLost')),
      ('found', t('adminReportsFilterFound')),
    ];

    return Scaffold(
      backgroundColor: AppColors.govBgLight,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openManualMatch,
        backgroundColor: AppColors.govGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.link),
        label: Text(t('adminManualMatchFab')),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (value, label) in filters)
                  ChoiceChip(
                    label: Text(label),
                    selected: _type == value,
                    onSelected: (selected) {
                      if (selected && _type != value) {
                        setState(() => _type = value);
                      }
                    },
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: AsyncView<List<AdminReport>>(
              key: ValueKey<String>('reports_${_type}_$_refreshSeed'),
              load: () => _repo.reports(type: _type),
              isEmpty: (items) => items.isEmpty,
              emptyText: t('adminEmptyReports'),
              builder: (context, reports, _) {
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                  itemCount: reports.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    return _AdminReportCard(report: report);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminReportCard extends StatelessWidget {
  const _AdminReportCard({required this.report});

  final AdminReport report;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ItemCard(
            item: report.item,
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.itemDetails,
              arguments: report.item,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.govBgLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                if (report.reporterName.isNotEmpty)
                  _ReporterChip(
                    icon: Icons.person_outline,
                    label: t('adminReporterLabel'),
                    value: report.reporterName,
                  ),
                if (report.reporterPhone.isNotEmpty)
                  _ReporterChip(
                    icon: Icons.phone_outlined,
                    label: t('adminReporterPhone'),
                    value: report.reporterPhone,
                  ),
                if (report.reporterEmail.isNotEmpty)
                  _ReporterChip(
                    icon: Icons.email_outlined,
                    label: t('adminReporterEmail'),
                    value: report.reporterEmail,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReporterChip extends StatelessWidget {
  const _ReporterChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.govGreen),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
