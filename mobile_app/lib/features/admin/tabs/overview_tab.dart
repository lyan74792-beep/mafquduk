// Overview tab: KPI stat tiles in a responsive grid, horizontal bar charts, and 260px FlutterMap heat map.
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/form_section.dart';
import '../../../data/models/admin.dart';
import '../../../data/repositories/admin_repository.dart';

class OverviewTab extends StatefulWidget {
  const OverviewTab({super.key});

  @override
  State<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<OverviewTab> {
  static const LatLng _haramCenter = LatLng(21.4225, 39.8262);
  final AdminRepository _repo = AdminRepository();

  @override
  Widget build(BuildContext context) {
    return AsyncView<AdminStats>(
      load: _repo.stats,
      builder: (context, stats, _) {
        final avgText =
            '${stats.avgReviewHours.toStringAsFixed(1)} ${t('adminHoursUnit')}';

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _StatsGrid(
              tiles: [
                _StatItem(
                  label: t('adminStatTotalLost'),
                  value: '${stats.totalLost}',
                  icon: Icons.search_outlined,
                  accent: AppColors.govGreen,
                ),
                _StatItem(
                  label: t('adminStatTotalFound'),
                  value: '${stats.totalFound}',
                  icon: Icons.inventory_2_outlined,
                  accent: AppColors.govGreen,
                ),
                _StatItem(
                  label: t('adminStatPendingMatches'),
                  value: '${stats.pendingMatches}',
                  icon: Icons.link_outlined,
                  accent: AppColors.govGoldBronze,
                ),
                _StatItem(
                  label: t('adminStatClaimsUnderReview'),
                  value: '${stats.claimsUnderReview}',
                  icon: Icons.verified_user_outlined,
                  accent: AppColors.warning,
                ),
                _StatItem(
                  label: t('adminStatActiveEmergencies'),
                  value: '${stats.activeEmergencies}',
                  icon: Icons.warning_amber_rounded,
                  accent: AppColors.danger,
                ),
                _StatItem(
                  label: t('adminStatAvgReviewHours'),
                  value: avgText,
                  icon: Icons.schedule_outlined,
                  accent: AppColors.govGoldBronze,
                ),
              ],
            ),
            const SizedBox(height: 16),
            FormSection(
              title: t('adminHeatmapTitle'),
              children: [
                Text(
                  t('adminHeatmapSubtitle'),
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    height: 260,
                    child: _HeatMapBox(
                      points: stats.heatPoints,
                      defaultCenter: _haramCenter,
                    ),
                  ),
                ),
              ],
            ),
            FormSection(
              title: t('adminByCategoryTitle'),
              children: [
                _HorizontalBarList(items: stats.byCategory),
              ],
            ),
            FormSection(
              title: t('adminTopLocationsTitle'),
              children: [
                _HorizontalBarList(items: stats.topLocations),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _StatItem {
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.tiles});

  final List<_StatItem> tiles;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 900 ? 6 : (width >= 560 ? 3 : 2);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tiles.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 98,
          ),
          itemBuilder: (context, index) {
            final item = tiles[index];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(item.icon, color: item.accent, size: 22),
                      Flexible(
                        child: Text(
                          item.value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: item.accent,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    item.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _HorizontalBarList extends StatelessWidget {
  const _HorizontalBarList({required this.items});

  final List<NamedCount> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          t('adminNoData'),
          style: const TextStyle(color: AppColors.muted, fontSize: 13),
        ),
      );
    }

    int maxCount = 1;
    for (final item in items) {
      if (item.count > maxCount) maxCount = item.count;
    }

    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${item.count}',
                      style: const TextStyle(
                        color: AppColors.govGreen,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.govBgLight,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.borderColor),
                  ),
                  alignment: AlignmentDirectional.centerStart,
                  child: FractionallySizedBox(
                    widthFactor: (item.count / maxCount).clamp(0.04, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.govGreen,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _HeatMapBox extends StatelessWidget {
  const _HeatMapBox({
    required this.points,
    required this.defaultCenter,
  });

  final List<HeatPoint> points;
  final LatLng defaultCenter;

  @override
  Widget build(BuildContext context) {
    final center = points.isNotEmpty
        ? LatLng(points.first.lat, points.first.lng)
        : defaultCenter;

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: 14,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.mafqoodak.mafqoodak',
            ),
            CircleLayer(
              circles: [
                for (final p in points)
                  CircleMarker(
                    point: LatLng(p.lat, p.lng),
                    radius: (10 + (p.weight * 4).clamp(0, 30)).toDouble(),
                    useRadiusInMeter: false,
                    color: AppColors.danger.withValues(alpha: .35),
                    borderColor: AppColors.govGoldBronze,
                    borderStrokeWidth: 1.5,
                  ),
              ],
            ),
          ],
        ),
        if (points.isEmpty)
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: Text(
                t('adminHeatmapEmpty'),
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }
}
