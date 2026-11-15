// Modal bottom sheet for cancelling an active lost item report with a lookup reason and optional details.
import 'package:flutter/material.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/async_view.dart';
import '../../data/models/lookups.dart';
import '../../data/repositories/lookup_repository.dart';
import '../../data/repositories/report_repository.dart';

Future<bool?> showCancelReportSheet(BuildContext context, int reportId) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (_) => CancelReportSheet(reportId: reportId),
  );
}

class CancelReportSheet extends StatefulWidget {
  const CancelReportSheet({
    super.key,
    required this.reportId,
  });

  final int reportId;

  static Future<bool?> show(BuildContext context, int reportId) =>
      showCancelReportSheet(context, reportId);

  @override
  State<CancelReportSheet> createState() => _CancelReportSheetState();
}

class _CancelReportSheetState extends State<CancelReportSheet> {
  final _repo = ReportRepository();
  final _lookupRepo = LookupRepository();
  late final TextEditingController _detailsController;

  String? _selectedReason;
  String? _reasonError;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _detailsController = TextEditingController();
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_selectedReason == null || _selectedReason!.trim().isEmpty) {
      setState(() => _reasonError = t('reportsCancelReasonRequired'));
      return;
    }

    setState(() {
      _reasonError = null;
      _submitting = true;
    });

    try {
      await _repo.cancelLost(
        widget.reportId,
        reason: _selectedReason!,
        details: _detailsController.text,
      );
      if (!mounted) return;
      showSnack(context, t('reportsCancelSuccess'));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      showSnack(context, errorText(e), isError: true);
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${t('reportsCancelSheetTitle')} #${widget.reportId}',
              style: const TextStyle(
                color: AppColors.govGreen,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              t('reportsCancelSheetSub'),
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Text(
              t('reportsCancelReasonLabel'),
              style: const TextStyle(
                color: AppColors.textColor,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 185,
              child: AsyncView<Lookups>(
                load: _lookupRepo.load,
                builder: (context, lookups, _) {
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: lookups.cancelReasons.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final reason = lookups.cancelReasons[index];
                      final selected = _selectedReason == reason;
                      return Semantics(
                        inMutuallyExclusiveGroup: true,
                        selected: selected,
                        button: true,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            setState(() {
                              _selectedReason = reason;
                              _reasonError = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.govGreen.withValues(alpha: 0.08)
                                  : AppColors.govBgLight,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected ? AppColors.govGreen : AppColors.borderColor,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  selected
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_off,
                                  color: selected ? AppColors.govGreen : AppColors.muted,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    tv(reason),
                                    style: TextStyle(
                                      color: AppColors.textColor,
                                      fontSize: 13,
                                      fontWeight:
                                          selected ? FontWeight.w700 : FontWeight.w500,
                                    ),
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
            ),
            if (_reasonError != null) ...[
              const SizedBox(height: 6),
              Text(
                _reasonError!,
                style: const TextStyle(color: AppColors.danger, fontSize: 12),
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _detailsController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: t('reportsCancelDetailsLabel'),
                hintText: t('reportsCancelDetailsHint'),
                prefixIcon: const Icon(Icons.notes_outlined),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
              ),
              onPressed: _submitting ? null : _confirm,
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(t('reportsCancelConfirmButton')),
            ),
          ],
        ),
      ),
    );
  }
}
