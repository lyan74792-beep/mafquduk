// Interactive map screen showing lost and found items with coordinates (AppRoutes.map).
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/l10n/l10n.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/item_card.dart';
import '../../data/models/item_summary.dart';
import '../../data/repositories/item_repository.dart';

class ItemsMapScreen extends StatefulWidget {
  const ItemsMapScreen({super.key});

  @override
  State<ItemsMapScreen> createState() => _ItemsMapScreenState();
}

class _ItemsMapScreenState extends State<ItemsMapScreen> {
  static const LatLng _haramCenter = LatLng(21.4225, 39.8262);

  final _repo = ItemRepository();
  String _type = 'all';
  List<ItemSummary> _items = const [];
  ItemSummary? _selectedItem;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPins();
  }

  Future<void> _loadPins() async {
    setState(() {
      _loading = true;
      _selectedItem = null;
    });
    try {
      final list = await _repo.mapItems(type: _type);
      if (!mounted) return;
      setState(() {
        _items = list.where((e) => e.lat != null && e.lng != null).toList(growable: false);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showSnack(context, errorText(e), isError: true);
    }
  }

  void _onFilterChanged(String type) {
    if (_type == type) return;
    setState(() => _type = type);
    _loadPins();
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedItem;

    return Scaffold(
      appBar: AppBar(
        title: Text(t('itemsMapTitle')),
        actions: [
          IconButton(
            tooltip: t('itemsMapRefreshTooltip'),
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _loadPins,
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: _haramCenter,
              initialZoom: 14,
              onTap: (_, _) => setState(() => _selectedItem = null),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.mafqoodak.mafqoodak',
              ),
              MarkerLayer(
                markers: _items
                    .map(
                      (item) => Marker(
                        point: LatLng(item.lat!, item.lng!),
                        width: 40,
                        height: 40,
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedItem = item),
                          child: Icon(
                            Icons.location_pin,
                            color: item.isFound
                                ? AppColors.success
                                : AppColors.warning,
                            size: 40,
                          ),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
          ),
          // Filter chips bar at top
          Positioned(
            top: 14,
            left: 16,
            right: 16,
            child: Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _MapFilterChip(
                      label: t('itemsFilterAll'),
                      selected: _type == 'all',
                      onSelected: () => _onFilterChanged('all'),
                    ),
                    const SizedBox(width: 8),
                    _MapFilterChip(
                      label: t('itemsFilterLost'),
                      selected: _type == 'lost',
                      onSelected: () => _onFilterChanged('lost'),
                    ),
                    const SizedBox(width: 8),
                    _MapFilterChip(
                      label: t('itemsFilterFound'),
                      selected: _type == 'found',
                      onSelected: () => _onFilterChanged('found'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_loading)
            const Positioned(
              top: 68,
              left: 0,
              right: 0,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
                ),
              ),
            )
          else if (_items.isEmpty)
            Positioned(
              top: 68,
              left: 24,
              right: 24,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Text(
                      t('itemsMapEmptyNotice'),
                      style: const TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ),
                ),
              ),
            ),
          if (selected != null)
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Stack(
                    children: [
                      ItemCard(
                        item: selected,
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.itemDetails,
                          arguments: selected,
                        ),
                      ),
                      PositionedDirectional(
                        top: 8,
                        end: 8,
                        child: Material(
                          color: Colors.white,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => setState(() => _selectedItem = null),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: AppColors.muted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MapFilterChip extends StatelessWidget {
  const _MapFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : AppColors.govGreen,
          fontWeight: FontWeight.w700,
        ),
      ),
      selected: selected,
      selectedColor: AppColors.govGreen,
      backgroundColor: Colors.white,
      checkmarkColor: Colors.white,
      side: const BorderSide(color: AppColors.govGreen),
      onSelected: (_) => onSelected(),
    );
  }
}
