// Manual match screen: lost/found open item dropdowns, ItemCard previews, and createMatch action.
import 'package:flutter/material.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/form_section.dart';
import '../../core/widgets/item_card.dart';
import '../../data/models/admin.dart';
import '../../data/models/item_summary.dart';
import '../../data/repositories/admin_repository.dart';

class ManualMatchScreen extends StatefulWidget {
  const ManualMatchScreen({super.key});

  @override
  State<ManualMatchScreen> createState() => _ManualMatchScreenState();
}

class _ManualMatchScreenState extends State<ManualMatchScreen> {
  final AdminRepository _repo = AdminRepository();
  int? _selectedLostId;
  int? _selectedFoundId;
  bool _submitting = false;

  String _formatOption(ItemSummary item) {
    final name = item.itemName.trim().isNotEmpty
        ? item.itemName.trim()
        : tv(item.category.trim());
    return '#${item.id} – $name – ${tv(item.category)}';
  }

  ItemSummary? _findById(List<ItemSummary> list, int? id) {
    if (id == null) return null;
    for (final item in list) {
      if (item.id == id) return item;
    }
    return null;
  }

  Future<void> _submitMatch() async {
    final lostId = _selectedLostId;
    final foundId = _selectedFoundId;
    if (lostId == null || foundId == null) {
      showSnack(context, t('adminMatchSelectBothError'), isError: true);
      return;
    }
    if (_submitting) return;

    setState(() => _submitting = true);
    try {
      await _repo.createMatch(lostId, foundId);
      if (!mounted) return;
      showSnack(context, t('adminMatchCreatedSuccess'));
      Navigator.pop(context, true);
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
    return Scaffold(
      backgroundColor: AppColors.govBgLight,
      appBar: AppBar(
        title: Text(t('adminManualMatchTitle')),
      ),
      body: AsyncView<OpenItems>(
        load: _repo.openItems,
        isEmpty: (open) => open.lost.isEmpty || open.found.isEmpty,
        emptyText: t('adminNoOpenItems'),
        emptyIcon: Icons.link_off_outlined,
        builder: (context, open, _) {
          final selectedLost = _findById(open.lost, _selectedLostId);
          final selectedFound = _findById(open.found, _selectedFoundId);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderColor),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link, color: AppColors.govGreen),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        t('adminManualMatchIntro'),
                        style: const TextStyle(
                          color: AppColors.textColor,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              FormSection(
                title: t('adminSelectLostItemLabel'),
                children: [
                  DropdownButtonFormField<int>(
                    key: ValueKey<int?>(_selectedLostId),
                    initialValue: selectedLost?.id,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: t('adminSelectLostItemLabel'),
                      prefixIcon: const Icon(Icons.search_outlined),
                    ),
                    items: open.lost
                        .map(
                          (item) => DropdownMenuItem<int>(
                            value: item.id,
                            child: Text(
                              _formatOption(item),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (val) => setState(() => _selectedLostId = val),
                  ),
                  if (selectedLost != null) ...[
                    Text(
                      t('adminLostPreviewSection'),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    ItemCard(item: selectedLost),
                  ],
                ],
              ),
              FormSection(
                title: t('adminSelectFoundItemLabel'),
                children: [
                  DropdownButtonFormField<int>(
                    key: ValueKey<int?>(_selectedFoundId),
                    initialValue: selectedFound?.id,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: t('adminSelectFoundItemLabel'),
                      prefixIcon: const Icon(Icons.inventory_2_outlined),
                    ),
                    items: open.found
                        .map(
                          (item) => DropdownMenuItem<int>(
                            value: item.id,
                            child: Text(
                              _formatOption(item),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (val) => setState(() => _selectedFoundId = val),
                  ),
                  if (selectedFound != null) ...[
                    Text(
                      t('adminFoundPreviewSection'),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    ItemCard(item: selectedFound),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: (_submitting ||
                        selectedLost == null ||
                        selectedFound == null)
                    ? null
                    : _submitMatch,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(t('adminConfirmMatchBtn')),
              ),
            ],
          );
        },
      ),
    );
  }
}
