// Emergencies tab: active/found/all filter chips, red-bordered emergency cards, and resolve action.
import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../data/models/admin.dart';
import '../../../data/repositories/admin_repository.dart';

class EmergenciesTab extends StatefulWidget {
  const EmergenciesTab({super.key});

  @override
  State<EmergenciesTab> createState() => _EmergenciesTabState();
}

class _EmergenciesTabState extends State<EmergenciesTab> {
  final AdminRepository _repo = AdminRepository();
  String _status = 'active';
  final Set<int> _resolvingIds = <int>{};

  Future<void> _confirmAndResolve(
    AdminEmergency emergency,
    Future<void> Function() reload,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('adminEmergencyConfirmTitle')),
        content: Text(t('adminEmergencyConfirmBody')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t('adminCancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t('adminConfirm')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _resolvingIds.add(emergency.id));
    try {
      await _repo.resolveEmergency(emergency.id);
      if (!mounted) return;
      showSnack(context, t('adminEmergencyResolvedSuccess'));
      await reload();
    } catch (e) {
      if (!mounted) return;
      showSnack(context, errorText(e), isError: true);
    } finally {
      if (mounted) {
        setState(() => _resolvingIds.remove(emergency.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filters = <(String, String)>[
      ('active', t('adminEmergencyFilterActive')),
      ('found', t('adminEmergencyFilterFound')),
      ('all', t('adminFilterAll')),
    ];

    return Column(
      children: [
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (value, label) in filters)
                ChoiceChip(
                  label: Text(label),
                  selected: _status == value,
                  onSelected: (selected) {
                    if (selected && _status != value) {
                      setState(() => _status = value);
                    }
                  },
                ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: AsyncView<List<AdminEmergency>>(
            key: ValueKey<String>('emergencies_$_status'),
            load: () => _repo.emergencies(status: _status),
            isEmpty: (items) => items.isEmpty,
            emptyText: t('adminEmptyEmergencies'),
            emptyIcon: Icons.warning_amber_rounded,
            builder: (context, items, reload) {
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final em = items[index];
                  final isBusy = _resolvingIds.contains(em.id);
                  return _EmergencyCard(
                    emergency: em,
                    isBusy: isBusy,
                    onMarkFound: () => _confirmAndResolve(em, reload),
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

class _EmergencyCard extends StatelessWidget {
  const _EmergencyCard({
    required this.emergency,
    required this.isBusy,
    required this.onMarkFound,
  });

  final AdminEmergency emergency;
  final bool isBusy;
  final VoidCallback onMarkFound;

  @override
  Widget build(BuildContext context) {
    final hasPhoto =
        emergency.photoUrl != null && emergency.photoUrl!.trim().isNotEmpty;
    final name = (emergency.personName ?? '').trim();
    final displayName = name.isEmpty ? t('adminEmergencyUnnamed') : name;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: emergency.isActive ? AppColors.danger : AppColors.borderColor,
          width: emergency.isActive ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 68,
                    height: 68,
                    child: hasPhoto
                        ? Image.network(
                            emergency.photoUrl!,
                            width: 68,
                            height: 68,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const _PhotoFallback(),
                          )
                        : const _PhotoFallback(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '#${emergency.id} · $displayName',
                              style: const TextStyle(
                                color: AppColors.danger,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          StatusChip(
                            status: emergency.status,
                            label: emergency.statusLabel,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _InfoLine(
                        icon: Icons.cake_outlined,
                        label: t('adminEmergencyAgeLabel'),
                        value: emergency.approxAge,
                      ),
                      _InfoLine(
                        icon: Icons.location_on_outlined,
                        label: t('adminEmergencyLastSeenLabel'),
                        value: emergency.lastSeenLocation,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            _InfoLine(
              icon: Icons.checkroom_outlined,
              label: t('adminEmergencyClothingLabel'),
              value: emergency.clothingDescription,
            ),
            _InfoLine(
              icon: Icons.phone_outlined,
              label: t('adminEmergencyReporterPhoneLabel'),
              value: emergency.reporterPhone,
            ),
            _InfoLine(
              icon: Icons.access_time_outlined,
              label: t('adminEmergencyTimeLabel'),
              value: emergency.createdAt,
            ),
            if (emergency.isActive) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: isBusy ? null : onMarkFound,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                ),
                icon: isBusy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(t('adminEmergencyMarkFoundBtn')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PhotoFallback extends StatelessWidget {
  const _PhotoFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.dangerSoft,
      alignment: Alignment.center,
      child: const Icon(
        Icons.person_search_outlined,
        color: AppColors.danger,
        size: 30,
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppColors.muted),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
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
