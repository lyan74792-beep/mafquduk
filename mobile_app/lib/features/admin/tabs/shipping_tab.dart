// Shipping tab: status filter chips, shipping request cards, and update bottom sheet.
import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../data/models/shipping.dart';
import '../../../data/repositories/admin_repository.dart';

class ShippingTab extends StatefulWidget {
  const ShippingTab({super.key});

  @override
  State<ShippingTab> createState() => _ShippingTabState();
}

class _ShippingTabState extends State<ShippingTab> {
  final AdminRepository _repo = AdminRepository();
  String _statusFilter = '';

  List<(String, String)> _statusOptions() => [
        ('pending', t('adminShippingStatusPending')),
        ('approved', t('adminShippingStatusApproved')),
        ('shipped', t('adminShippingStatusShipped')),
        ('delivered', t('adminShippingStatusDelivered')),
        ('rejected', t('adminShippingStatusRejected')),
      ];

  Future<void> _openUpdateSheet(
    ShippingRequest req,
    Future<void> Function() reload,
  ) async {
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _ShippingUpdateSheet(
        request: req,
        repo: _repo,
        statusOptions: _statusOptions(),
      ),
    );
    if (updated == true && mounted) {
      await reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filters = <(String, String)>[
      ('', t('adminShippingStatusAll')),
      ..._statusOptions(),
    ];

    return Column(
      children: [
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final (value, label) in filters)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: _statusFilter == value,
                      onSelected: (selected) {
                        if (selected && _statusFilter != value) {
                          setState(() => _statusFilter = value);
                        }
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: AsyncView<List<ShippingRequest>>(
            key: ValueKey<String>('shipping_$_statusFilter'),
            load: () => _repo.shipping(status: _statusFilter),
            isEmpty: (items) => items.isEmpty,
            emptyText: t('adminEmptyShipping'),
            emptyIcon: Icons.local_shipping_outlined,
            builder: (context, requests, reload) {
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: requests.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final req = requests[index];
                  return _ShippingRequestCard(
                    request: req,
                    onUpdate: () => _openUpdateSheet(req, reload),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ShippingRequestCard extends StatelessWidget {
  const _ShippingRequestCard({
    required this.request,
    required this.onUpdate,
  });

  final ShippingRequest request;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    final recipient = (request.userName != null && request.userName!.isNotEmpty)
        ? request.userName!
        : '—';
    final contactPhone = request.phone.isNotEmpty
        ? request.phone
        : (request.userPhone ?? '');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.local_shipping, color: AppColors.govGreen),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${t('adminShippingRequestPrefix')}${request.id} — ${request.itemName}',
                  style: const TextStyle(
                    color: AppColors.govGreen,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              StatusChip(status: request.status, label: request.statusLabel),
            ],
          ),
          const Divider(height: 18),
          _Line(label: t('adminShippingRecipientLabel'), value: recipient),
          _Line(label: t('adminShippingPhoneLabel'), value: contactPhone),
          _Line(label: t('adminShippingCityLabel'), value: request.city),
          _Line(label: t('adminShippingAddressLabel'), value: request.address),
          if (request.notes != null && request.notes!.trim().isNotEmpty)
            _Line(label: t('adminShippingNotesLabel'), value: request.notes!),
          if (request.carrier != null && request.carrier!.trim().isNotEmpty)
            _Line(
              label: t('adminShippingCarrierLabel'),
              value: request.carrier!,
            ),
          if (request.trackingNumber != null &&
              request.trackingNumber!.trim().isNotEmpty)
            _Line(
              label: t('adminShippingTrackingLabel'),
              value: request.trackingNumber!,
            ),
          if (request.adminNote != null &&
              request.adminNote!.trim().isNotEmpty)
            _Line(
              label: t('adminShippingAdminNoteLabel'),
              value: request.adminNote!,
            ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onUpdate,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: Text(t('adminShippingUpdateBtn')),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShippingUpdateSheet extends StatefulWidget {
  const _ShippingUpdateSheet({
    required this.request,
    required this.repo,
    required this.statusOptions,
  });

  final ShippingRequest request;
  final AdminRepository repo;
  final List<(String, String)> statusOptions;

  @override
  State<_ShippingUpdateSheet> createState() => _ShippingUpdateSheetState();
}

class _ShippingUpdateSheetState extends State<_ShippingUpdateSheet> {
  late String _status;
  late final TextEditingController _carrierCtrl;
  late final TextEditingController _trackingCtrl;
  late final TextEditingController _noteCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final validCodes = widget.statusOptions.map((e) => e.$1).toSet();
    _status = validCodes.contains(widget.request.status)
        ? widget.request.status
        : 'pending';
    _carrierCtrl = TextEditingController(text: widget.request.carrier ?? '');
    _trackingCtrl =
        TextEditingController(text: widget.request.trackingNumber ?? '');
    _noteCtrl = TextEditingController(text: widget.request.adminNote ?? '');
  }

  @override
  void dispose() {
    _carrierCtrl.dispose();
    _trackingCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await widget.repo.updateShipping(
        widget.request.id,
        status: _status,
        carrier: _carrierCtrl.text,
        trackingNumber: _trackingCtrl.text,
        adminNote: _noteCtrl.text,
      );
      if (!mounted) return;
      showSnack(context, t('adminShippingUpdatedSuccess'));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      showSnack(context, errorText(e), isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 20, 16, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t('adminShippingSheetTitle'),
              style: const TextStyle(
                color: AppColors.govGreen,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: InputDecoration(
                labelText: t('adminShippingStatusFieldLabel'),
                prefixIcon: const Icon(Icons.flag_outlined),
              ),
              items: [
                for (final (code, label) in widget.statusOptions)
                  DropdownMenuItem<String>(value: code, child: Text(label)),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _status = v);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _carrierCtrl,
              decoration: InputDecoration(
                labelText: t('adminShippingCarrierLabel'),
                hintText: t('adminShippingCarrierHint'),
                prefixIcon: const Icon(Icons.local_shipping_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _trackingCtrl,
              decoration: InputDecoration(
                labelText: t('adminShippingTrackingLabel'),
                hintText: t('adminShippingTrackingHint'),
                prefixIcon: const Icon(Icons.qr_code_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: t('adminShippingAdminNoteLabel'),
                hintText: t('adminShippingAdminNoteHint'),
                prefixIcon: const Icon(Icons.note_outlined),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(t('adminShippingSaveBtn')),
            ),
          ],
        ),
      ),
    );
  }
}
