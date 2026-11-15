// Full item details screen with image carousel, metadata, map preview, and claim action (AppRoutes.itemDetails).
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/l10n/l10n.dart';
import '../../core/routes/app_routes.dart';
import '../../core/session/session.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/form_section.dart';
import '../../core/widgets/status_chip.dart';
import '../../data/models/item_summary.dart';
import '../../data/repositories/item_repository.dart';

class ItemDetailsScreen extends StatefulWidget {
  const ItemDetailsScreen({super.key});

  @override
  State<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> {
  final _repo = ItemRepository();

  Future<void> _onClaimPressed(
    BuildContext context,
    ItemDetails details,
    Future<void> Function() reload,
  ) async {
    final session = Session.instance;
    if (!session.isLoggedIn || !session.isUser) {
      showSnack(context, t('itemsLoginToClaimNotice'));
      await Navigator.pushNamed(context, AppRoutes.login);
      return;
    }
    final claimed = await Navigator.pushNamed(
      context,
      AppRoutes.claimItem,
      arguments: details,
    );
    if (claimed == true && mounted) {
      await reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = ModalRoute.of(context)!.settings.arguments as ItemSummary;

    return Scaffold(
      appBar: AppBar(
        title: Text(t('itemsDetailsTitle')),
      ),
      body: AsyncView<ItemDetails>(
        load: () => _repo.details(summary.type, summary.id),
        builder: (context, details, reload) {
          final images = details.images.isNotEmpty
              ? details.images
              : (details.imageUrl != null && details.imageUrl!.trim().isNotEmpty)
                  ? <String>[details.imageUrl!]
                  : const <String>[];
          final canClaim = details.isFound &&
              (details.status == 'received' || details.status == 'matched');
          final hasCoords = details.lat != null && details.lng != null;
          final displayTitle =
              details.itemName.isNotEmpty ? details.itemName : tv(details.category);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _ImageCarousel(images: images, isFound: details.isFound),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            details.isSighting
                                ? Icons.visibility_outlined
                                : details.isFound
                                    ? Icons.inventory_2_outlined
                                    : Icons.search_outlined,
                            color: AppColors.govGreen,
                            size: 26,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              displayTitle,
                              style: const TextStyle(
                                color: AppColors.govGreenDark,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusChip(
                            status: details.status,
                            label: details.statusLabel,
                          ),
                        ],
                      ),
                      const Divider(height: 24, color: AppColors.borderColor),
                      _DetailInfoRow(
                        icon: Icons.category_outlined,
                        label: t('itemsCategoryLabel'),
                        value: tv(details.category),
                      ),
                      if (details.location.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _DetailInfoRow(
                          icon: Icons.location_on_outlined,
                          label: t('itemsLocationLabel'),
                          value: tv(details.location),
                        ),
                      ],
                      if (details.date != null && details.date!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _DetailInfoRow(
                          icon: Icons.calendar_today_outlined,
                          label: t('itemsDateLabel'),
                          value: details.date!,
                        ),
                      ],
                      if (details.isFound &&
                          details.currentStatus != null &&
                          details.currentStatus!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _DetailInfoRow(
                          icon: Icons.info_outline,
                          label: t('itemsCurrentStatusLabel'),
                          value: tv(details.currentStatus!),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (details.description.isNotEmpty)
                FormSection(
                  title: t('itemsDescriptionSection'),
                  children: [
                    Text(
                      details.description,
                      style: const TextStyle(
                        color: AppColors.textColor,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              if (hasCoords)
                FormSection(
                  title: t('itemsMapPreviewSection'),
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        height: 190,
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: LatLng(details.lat!, details.lng!),
                            initialZoom: 14,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.mafqoodak.mafqoodak',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(details.lat!, details.lng!),
                                  width: 40,
                                  height: 40,
                                  child: Icon(
                                    Icons.location_pin,
                                    color: details.isFound
                                        ? AppColors.success
                                        : AppColors.warning,
                                    size: 40,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              if (canClaim) ...[
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.govGoldBronze,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _onClaimPressed(context, details, reload),
                  icon: const Icon(Icons.verified_user_outlined),
                  label: Text(t('itemsClaimThisButton')),
                ),
              ],
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

class _ImageCarousel extends StatefulWidget {
  const _ImageCarousel({required this.images, required this.isFound});

  final List<String> images;
  final bool isFound;

  @override
  State<_ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<_ImageCarousel> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.isFound ? Icons.inventory_2_outlined : Icons.search_outlined,
              size: 56,
              color: AppColors.muted,
            ),
            const SizedBox(height: 8),
            Text(
              t('itemsNoImage'),
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 220,
            child: PageView.builder(
              itemCount: widget.images.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, index) {
                return Image.network(
                  widget.images[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, _, _) => Container(
                    color: Colors.white,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.broken_image_outlined,
                      size: 48,
                      color: AppColors.muted,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        if (widget.images.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.images.length, (i) {
              final active = i == _index;
              return Container(
                width: active ? 18 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: active ? AppColors.govGreen : AppColors.borderColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

class _DetailInfoRow extends StatelessWidget {
  const _DetailInfoRow({
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.govGoldBronze),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(color: AppColors.muted, fontSize: 13),
        ),
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
