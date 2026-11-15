// Reusable card displaying a lost, found, or sighting [ItemSummary].
import 'package:flutter/material.dart';

import '../../data/models/item_summary.dart';
import '../l10n/l10n.dart';
import '../theme/app_colors.dart';
import 'status_chip.dart';

class ItemCard extends StatelessWidget {
  const ItemCard({
    super.key,
    required this.item,
    this.onTap,
  });

  final ItemSummary item;
  final VoidCallback? onTap;

  String _typeLabel() {
    if (item.isSighting) return t('typeSighting');
    if (item.isFound) return t('typeFound');
    return t('typeLost');
  }

  Color _typeColor() {
    if (item.isSighting) return AppColors.warning;
    if (item.isFound) return AppColors.govGreen;
    return AppColors.govGoldBronze;
  }

  IconData _fallbackIcon() {
    if (item.isSighting) return Icons.visibility_outlined;
    if (item.isFound) return Icons.inventory_2_outlined;
    return Icons.search_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _typeColor();
    final hasImage = item.imageUrl != null && item.imageUrl!.trim().isNotEmpty;
    final subtitleParts = <String>[
      if (item.category.isNotEmpty) tv(item.category),
      if (item.location.isNotEmpty) tv(item.location),
    ];

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.borderColor),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: hasImage
                      ? Image.network(
                          item.imageUrl!,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _PlaceholderBox(
                            icon: _fallbackIcon(),
                            color: typeColor,
                          ),
                        )
                      : _PlaceholderBox(
                          icon: _fallbackIcon(),
                          color: typeColor,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: typeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _typeLabel(),
                            style: TextStyle(
                              color: typeColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.itemName.isNotEmpty ? item.itemName : tv(item.category),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (subtitleParts.isNotEmpty)
                      Text(
                        subtitleParts.join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (item.date != null && item.date!.isNotEmpty) ...[
                          const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.muted),
                          const SizedBox(width: 4),
                          Text(
                            item.date!,
                            style: const TextStyle(color: AppColors.muted, fontSize: 11),
                          ),
                        ],
                        const Spacer(),
                        StatusChip(status: item.status, label: item.statusLabel),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceholderBox extends StatelessWidget {
  const _PlaceholderBox({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.govBgLight,
      alignment: Alignment.center,
      child: Icon(icon, color: color, size: 28),
    );
  }
}
