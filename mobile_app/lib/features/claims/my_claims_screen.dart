// User's ownership claims screen with review details and delivery request option (AppRoutes.myClaims).
import 'package:flutter/material.dart';

import '../../core/l10n/l10n.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/item_card.dart';
import '../../core/widgets/status_chip.dart';
import '../../data/models/claim.dart';
import '../../data/repositories/claim_repository.dart';

class MyClaimsScreen extends StatefulWidget {
  const MyClaimsScreen({super.key});

  @override
  State<MyClaimsScreen> createState() => _MyClaimsScreenState();
}

class _MyClaimsScreenState extends State<MyClaimsScreen> {
  final _repo = ClaimRepository();

  Future<void> _openShippingRequest(
    BuildContext context,
    Claim claim,
    Future<void> Function() reload,
  ) async {
    final created = await Navigator.pushNamed(
      context,
      AppRoutes.shippingRequest,
      arguments: claim,
    );
    if (created == true && mounted) {
      await reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t('itemsMyClaimsTitle')),
      ),
      body: AsyncView<List<Claim>>(
        load: _repo.myClaims,
        isEmpty: (list) => list.isEmpty,
        emptyText: t('itemsMyClaimsEmpty'),
        emptyIcon: Icons.assignment_turned_in_outlined,
        builder: (context, claims, reload) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: claims.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    t('itemsMyClaimsPickupNotice'),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                );
              }
              final claim = claims[index - 1];
              return _ClaimCard(
                claim: claim,
                onRequestShipping: () =>
                    _openShippingRequest(context, claim, reload),
              );
            },
          );
        },
      ),
    );
  }
}

class _ClaimCard extends StatelessWidget {
  const _ClaimCard({
    required this.claim,
    required this.onRequestShipping,
  });

  final Claim claim;
  final VoidCallback onRequestShipping;

  @override
  Widget build(BuildContext context) {
    final hasReviewDate =
        claim.reviewedAt != null && claim.reviewedAt!.trim().isNotEmpty;
    final hasRejectReason =
        claim.rejectReason != null && claim.rejectReason!.trim().isNotEmpty;
    final shipping = claim.shipping;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  '${t('itemsClaimIdLabel')} #${claim.claimId}',
                  style: const TextStyle(
                    color: AppColors.govGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                StatusChip(
                  status: claim.status,
                  label: claim.statusLabel,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 14,
              runSpacing: 4,
              children: [
                if (claim.claimDate.isNotEmpty)
                  Text(
                    '${t('itemsClaimDateLabel')}: ${claim.claimDate}',
                    style: const TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                if (hasReviewDate)
                  Text(
                    '${t('itemsClaimReviewedDateLabel')}: ${claim.reviewedAt}',
                    style: const TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            ItemCard(
              item: claim.item,
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.itemDetails,
                arguments: claim.item,
              ),
            ),
            if (hasRejectReason) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.dangerSoft,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.danger.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 18,
                      color: AppColors.danger,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${t('itemsClaimRejectReasonPrefix')}: ${claim.rejectReason}',
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (claim.canRequestShipping) ...[
              const SizedBox(height: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.govGoldBronze,
                  foregroundColor: Colors.white,
                ),
                onPressed: onRequestShipping,
                icon: const Icon(Icons.local_shipping_outlined, size: 18),
                label: Text(t('itemsRequestDeliveryButton')),
              ),
            ],
            if (shipping != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.govBgLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.local_shipping_outlined,
                          size: 18,
                          color: AppColors.govGreen,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            t('itemsClaimShippingSection'),
                            style: const TextStyle(
                              color: AppColors.govGreen,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        StatusChip(
                          status: shipping.status,
                          label: shipping.statusLabel,
                        ),
                      ],
                    ),
                    if (shipping.carrier != null &&
                        shipping.carrier!.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        '${t('itemsShippingCarrierLabel')}: ${shipping.carrier}',
                        style: const TextStyle(
                          color: AppColors.textColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (shipping.trackingNumber != null &&
                        shipping.trackingNumber!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${t('itemsShippingTrackingLabel')}: ${shipping.trackingNumber}',
                        style: const TextStyle(
                          color: AppColors.textColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
