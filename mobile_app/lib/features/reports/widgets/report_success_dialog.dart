// Shared confirmation dialog shown after creating a lost, found, sighting, or emergency report.
import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';

Future<String?> showReportSuccessDialog(
  BuildContext context, {
  required int reportId,
  required String title,
  required String body,
  int matchesFound = 0,
  bool isEmergency = false,
}) {
  final accentColor = isEmergency ? AppColors.danger : AppColors.govGreen;

  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.borderColor),
      ),
      title: Column(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: accentColor.withValues(alpha: 0.12),
            child: Icon(
              isEmergency ? Icons.crisis_alert_outlined : Icons.check_circle_outline,
              color: accentColor,
              size: 30,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: accentColor,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.govBgLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${t('reportsReportNumberLabel')}: ',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '#$reportId',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textColor,
              fontSize: 13,
            ),
          ),
          if (matchesFound > 0) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.govGoldBronze.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.govGoldBronze),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome_outlined, color: AppColors.govGoldBronze, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${t('reportsMatchesFoundNotice')} $matchesFound',
                          style: const TextStyle(
                            color: AppColors.govGreenDark,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(dialogContext).pop('matches'),
                    icon: const Icon(Icons.compare_arrows_outlined, size: 18),
                    label: Text(t('reportsViewMatchesButton')),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: isEmergency
                ? ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                  )
                : null,
            onPressed: () => Navigator.of(dialogContext).pop('done'),
            child: Text(t('reportsDoneButton')),
          ),
        ),
      ],
    ),
  );
}
