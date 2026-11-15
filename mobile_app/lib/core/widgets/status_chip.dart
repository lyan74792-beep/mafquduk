// Pill-shaped status badge coloured according to the Mafqoodak status lifecycle.
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.status,
    this.label,
  });

  final String status;
  final String? label;

  static Color colorFor(String status) {
    switch (status) {
      case 'searching':
      case 'pending':
      case 'Under Review':
      case 'active':
        return AppColors.warning;
      case 'matched':
      case 'approved':
      case 'Approved':
      case 'ready':
      case 'shipped':
      case 'claimed':
        return AppColors.govGoldBronze;
      case 'delivered':
      case 'Delivered':
      case 'received':
      case 'found':
        return AppColors.success;
      case 'cancelled':
      case 'rejected':
      case 'Rejected':
        return AppColors.danger;
      default:
        return AppColors.muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = colorFor(status);
    final displayText = (label != null && label!.trim().isNotEmpty) ? label! : status;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        displayText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
