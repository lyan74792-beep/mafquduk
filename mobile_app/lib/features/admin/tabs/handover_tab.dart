// Handover tab: 'Approved' claims with 'mark delivered' action, plus collapsible list of recent 'Delivered' claims.
import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../data/models/admin.dart';
import '../../../data/repositories/admin_repository.dart';

class _HandoverData {
  const _HandoverData({
    required this.approved,
    required this.delivered,
  });

  final List<AdminClaim> approved;
  final List<AdminClaim> delivered;
}

class HandoverTab extends StatefulWidget {
  const HandoverTab({super.key});

  @override
  State<HandoverTab> createState() => _HandoverTabState();
}

class _HandoverTabState extends State<HandoverTab> {
  final AdminRepository _repo = AdminRepository();
  final Set<int> _deliveringIds = <int>{};

  Future<_HandoverData> _loadAll() async {
    final results = await Future.wait<List<AdminClaim>>([
      _repo.claims(status: 'Approved'),
      _repo.claims(status: 'Delivered'),
    ]);
    return _HandoverData(
      approved: results[0],
      delivered: results[1],
    );
  }

  Future<void> _confirmAndDeliver(
    AdminClaim claim,
    Future<void> Function() reload,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('adminDeliverConfirmTitle')),
        content: Text(t('adminDeliverConfirmBody')),
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

    setState(() => _deliveringIds.add(claim.claimId));
    try {
      await _repo.deliverClaim(claim.claimId);
      if (!mounted) return;
      showSnack(context, t('adminDeliverSuccess'));
      await reload();
    } catch (e) {
      if (!mounted) return;
      showSnack(context, errorText(e), isError: true);
    } finally {
      if (mounted) {
        setState(() => _deliveringIds.remove(claim.claimId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AsyncView<_HandoverData>(
      load: _loadAll,
      builder: (context, data, reload) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              t('adminHandoverReadySection'),
              style: const TextStyle(
                color: AppColors.govGreen,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            if (data.approved.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderColor),
                ),
                child: Text(
                  t('adminHandoverEmptyReady'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              )
            else
              for (final claim in data.approved) ...[
                _HandoverClaimCard(
                  claim: claim,
                  isBusy: _deliveringIds.contains(claim.claimId),
                  onDeliver: () => _confirmAndDeliver(claim, reload),
                ),
                const SizedBox(height: 12),
              ],
            const SizedBox(height: 16),
            Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.borderColor),
              ),
              child: ExpansionTile(
                leading: const Icon(
                  Icons.history_outlined,
                  color: AppColors.govGreen,
                ),
                title: Text(
                  '${t('adminRecentDeliveredTitle')} (${data.delivered.length})',
                  style: const TextStyle(
                    color: AppColors.govGreen,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  if (data.delivered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        t('adminEmptyDelivered'),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                        ),
                      ),
                    )
                  else
                    for (final claim in data.delivered) ...[
                      const Divider(height: 16),
                      _HandoverClaimCard(
                        claim: claim,
                        isBusy: false,
                        onDeliver: null,
                      ),
                    ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HandoverClaimCard extends StatelessWidget {
  const _HandoverClaimCard({
    required this.claim,
    required this.isBusy,
    this.onDeliver,
  });

  final AdminClaim claim;
  final bool isBusy;
  final VoidCallback? onDeliver;

  @override
  Widget build(BuildContext context) {
    final itemTitle = claim.item.itemName.isNotEmpty
        ? claim.item.itemName
        : tv(claim.item.category);

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
              const Icon(
                Icons.inventory_2_outlined,
                color: AppColors.govGreen,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$itemTitle (${t('adminClaimIdPrefix')}${claim.claimId})',
                  style: const TextStyle(
                    color: AppColors.govGreen,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              StatusChip(status: claim.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${claim.claimantName} · ${claim.claimantPhone} · ${tv(claim.item.location)}',
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          if (onDeliver != null) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: isBusy ? null : onDeliver,
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
              label: Text(t('adminMarkDeliveredBtn')),
            ),
          ],
        ],
      ),
    );
  }
}
