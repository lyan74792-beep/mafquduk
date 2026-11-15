// Public lost-item report tracking screen (AppRoutes.trackReport; no login required).
import 'package:flutter/material.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/form_section.dart';
import '../../core/widgets/status_chip.dart';
import '../../data/models/report.dart';
import '../../data/repositories/report_repository.dart';

class TrackReportScreen extends StatefulWidget {
  const TrackReportScreen({super.key});

  @override
  State<TrackReportScreen> createState() => _TrackReportScreenState();
}

class _TrackReportScreenState extends State<TrackReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = ReportRepository();
  late final TextEditingController _idController;

  bool _loading = false;
  TrackResult? _result;

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController();
  }

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  String? _idValidator(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return t('fieldRequired');
    final parsed = int.tryParse(text);
    if (parsed == null || parsed <= 0) return t('reportsTrackInvalidId');
    return null;
  }

  Future<void> _track() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final id = int.parse(_idController.text.trim());
    setState(() => _loading = true);
    try {
      final res = await _repo.track(id);
      if (!mounted) return;
      setState(() => _result = res);
    } catch (e) {
      if (!mounted) return;
      showSnack(context, errorText(e), isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return Scaffold(
      appBar: AppBar(title: Text(t('reportsTrackTitle'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t('reportsTrackIntro'),
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 14),
            Form(
              key: _formKey,
              // re-check a field as soon as the user edits it (clears stale errors)
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: FormSection(
                title: t('reportsTrackIdLabel'),
                children: [
                  TextFormField(
                    controller: _idController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.search,
                    onFieldSubmitted: (_) => _track(),
                    decoration: InputDecoration(
                      labelText: t('reportsTrackIdLabel'),
                      hintText: t('reportsTrackIdHint'),
                      prefixIcon: const Icon(Icons.tag),
                    ),
                    validator: _idValidator,
                  ),
                  ElevatedButton.icon(
                    onPressed: _loading ? null : _track,
                    icon: _loading
                        ? const SizedBox.shrink()
                        : const Icon(Icons.manage_search_outlined),
                    label: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(t('reportsTrackButton')),
                  ),
                ],
              ),
            ),
            if (result != null) ...[
              _TrackResultCard(result: result),
              const SizedBox(height: 16),
              _TrackStagesTimeline(status: result.status),
            ],
          ],
        ),
      ),
    );
  }
}

class _TrackResultCard extends StatelessWidget {
  const _TrackResultCard({required this.result});

  final TrackResult result;

  @override
  Widget build(BuildContext context) {
    return FormSection(
      title: t('reportsTrackResultTitle'),
      children: [
        Row(
          children: [
            Text(
              '#${result.id}',
              style: const TextStyle(
                color: AppColors.govGreen,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            StatusChip(status: result.status, label: result.statusLabel),
          ],
        ),
        const Divider(color: AppColors.borderColor, height: 1),
        _InfoRow(
          icon: Icons.category_outlined,
          label: t('reportsCategoryLabel'),
          value: tv(result.category),
        ),
        _InfoRow(
          icon: Icons.calendar_today_outlined,
          label: t('reportsTrackCreatedDate'),
          value: result.createdAt,
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.muted),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(color: AppColors.muted, fontSize: 13)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.textColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _TrackStagesTimeline extends StatelessWidget {
  const _TrackStagesTimeline({required this.status});

  final String status;

  static const List<String> _orderedKeys = ['searching', 'matched', 'ready', 'delivered'];

  @override
  Widget build(BuildContext context) {
    final isCancelled = status == 'cancelled';
    final currentIndex = _orderedKeys.indexOf(status);
    final stages = <({String key, String title, String subtitle})>[
      (
        key: 'searching',
        title: t('reportsStageSearchingTitle'),
        subtitle: t('reportsStageSearchingSub'),
      ),
      (
        key: 'matched',
        title: t('reportsStageMatchedTitle'),
        subtitle: t('reportsStageMatchedSub'),
      ),
      (
        key: 'ready',
        title: t('reportsStageReadyTitle'),
        subtitle: t('reportsStageReadySub'),
      ),
      (
        key: 'delivered',
        title: t('reportsStageDeliveredTitle'),
        subtitle: t('reportsStageDeliveredSub'),
      ),
    ];

    return FormSection(
      title: t('reportsTrackStagesTitle'),
      children: [
        if (isCancelled)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.dangerSoft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.danger),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.cancel_outlined, color: AppColors.danger, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t('reportsStageCancelledTitle'),
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        t('reportsStageCancelledSub'),
                        style: const TextStyle(color: AppColors.textColor, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        Column(
          children: List.generate(stages.length, (index) {
            final stage = stages[index];
            final isLast = index == stages.length - 1;
            final isCompleted = !isCancelled && currentIndex >= index;
            final isCurrent = !isCancelled && currentIndex == index;
            final dotColor = isCancelled
                ? AppColors.muted
                : isCurrent
                    ? AppColors.govGoldBronze
                    : isCompleted
                        ? AppColors.success
                        : AppColors.borderColor;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? dotColor.withValues(alpha: 0.16)
                              : AppColors.govBgLight,
                          shape: BoxShape.circle,
                          border: Border.all(color: dotColor, width: 2),
                        ),
                        child: Icon(
                          isCompleted ? Icons.check : Icons.circle,
                          size: isCompleted ? 15 : 8,
                          color: dotColor,
                        ),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 2,
                            constraints: const BoxConstraints(minHeight: 28),
                            color: (!isCancelled && currentIndex > index)
                                ? AppColors.success
                                : AppColors.borderColor,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stage.title,
                            style: TextStyle(
                              color: isCompleted ? AppColors.textColor : AppColors.muted,
                              fontSize: 14,
                              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            stage.subtitle,
                            style: const TextStyle(color: AppColors.muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}
