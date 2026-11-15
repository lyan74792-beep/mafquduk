// Reusable location input block: landmark dropdown, conditional "other" field, and map point picker.
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/location_picker_screen.dart';
import '../../../core/widgets/lookup_dropdown.dart';
import '../../../data/models/lookups.dart';

/// Controller holding the selected landmark, custom "other" text, and optional map coordinates.
class LocationValue extends ChangeNotifier {
  LocationValue({
    this.landmark = '',
    this.other = '',
    this.lat,
    this.lng,
  });

  String landmark;
  String other;
  double? lat;
  double? lng;

  bool get hasCoordinates => lat != null && lng != null;

  void setLandmark(String value, {List<Landmark> landmarks = const []}) {
    landmark = value;
    final match = landmarks.where((l) => l.name == value).firstOrNull;
    if (match == null || !match.isOther) {
      other = '';
    }
    notifyListeners();
  }

  void setOther(String value) {
    other = value;
    notifyListeners();
  }

  void setCoordinates(double? latitude, double? longitude) {
    lat = latitude;
    lng = longitude;
    notifyListeners();
  }

  void clearCoordinates() {
    lat = null;
    lng = null;
    notifyListeners();
  }
}

class LocationFields extends StatefulWidget {
  const LocationFields({
    super.key,
    required this.controller,
    required this.landmarks,
    this.label,
    this.errorText,
    this.otherErrorText,
    this.showMapPicker = true,
    this.onChanged,
  });

  final LocationValue controller;
  final List<Landmark> landmarks;
  final String? label;
  final String? errorText;
  final String? otherErrorText;
  final bool showMapPicker;
  final VoidCallback? onChanged;

  @override
  State<LocationFields> createState() => _LocationFieldsState();
}

class _LocationFieldsState extends State<LocationFields> {
  late final TextEditingController _otherController;

  @override
  void initState() {
    super.initState();
    _otherController = TextEditingController(text: widget.controller.other);
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant LocationFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
      if (_otherController.text != widget.controller.other) {
        _otherController.text = widget.controller.other;
      }
    }
  }

  void _onControllerChanged() {
    if (_otherController.text != widget.controller.other) {
      _otherController.value = TextEditingValue(
        text: widget.controller.other,
        selection: TextSelection.collapsed(offset: widget.controller.other.length),
      );
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _otherController.dispose();
    super.dispose();
  }

  Landmark? _selectedLandmark() {
    final name = widget.controller.landmark;
    if (name.isEmpty) return null;
    for (final l in widget.landmarks) {
      if (l.name == name) return l;
    }
    return null;
  }

  bool _isOtherSelected() => _selectedLandmark()?.isOther ?? false;

  Future<void> _pickOnMap() async {
    LatLng? initial;
    if (widget.controller.hasCoordinates) {
      initial = LatLng(widget.controller.lat!, widget.controller.lng!);
    } else {
      final selected = _selectedLandmark();
      if (selected?.lat != null && selected?.lng != null) {
        initial = LatLng(selected!.lat!, selected.lng!);
      }
    }

    final picked = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute<LatLng>(
        builder: (_) => LocationPickerScreen(initial: initial),
      ),
    );
    if (picked != null && mounted) {
      widget.controller.setCoordinates(picked.latitude, picked.longitude);
      widget.onChanged?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.landmarks.map((l) => l.name).toList(growable: false);
    final currentLandmark = widget.controller.landmark.isEmpty ? null : widget.controller.landmark;
    final showOther = _isOtherSelected();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LookupDropdown(
          label: widget.label ?? t('reportsLandmarkLabel'),
          options: options,
          value: currentLandmark,
          icon: Icons.location_on_outlined,
          validator: (v) => widget.errorText ?? requiredField(v),
          onChanged: (v) {
            widget.controller.setLandmark(v ?? '', landmarks: widget.landmarks);
            widget.onChanged?.call();
          },
        ),
        if (widget.errorText != null && widget.errorText!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              widget.errorText!,
              style: const TextStyle(color: AppColors.danger, fontSize: 12),
            ),
          ),
        ],
        if (showOther) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _otherController,
            decoration: InputDecoration(
              labelText: t('reportsLocationOtherLabel'),
              hintText: t('reportsLocationOtherHint'),
              prefixIcon: const Icon(Icons.edit_location_alt_outlined),
            ),
            forceErrorText: widget.otherErrorText,
            validator: requiredField,
            onChanged: (v) {
              widget.controller.setOther(v);
              widget.onChanged?.call();
            },
          ),
        ],
        if (widget.showMapPicker) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickOnMap,
            icon: const Icon(Icons.map_outlined, size: 18),
            label: Text(t('reportsPickExactMapPoint')),
          ),
          if (widget.controller.hasCoordinates) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.govBgLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: Row(
                children: [
                  const Icon(Icons.my_location, size: 16, color: AppColors.govGreen),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${t('reportsSelectedCoordinates')}: '
                      '${widget.controller.lat!.toStringAsFixed(5)}, '
                      '${widget.controller.lng!.toStringAsFixed(5)}',
                      style: const TextStyle(
                        color: AppColors.textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: t('reportsClearCoordinates'),
                    onPressed: () {
                      widget.controller.clearCoordinates();
                      widget.onChanged?.call();
                    },
                    icon: const Icon(Icons.close, size: 18, color: AppColors.danger),
                  ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }
}
