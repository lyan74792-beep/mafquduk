// User's postal shipping requests screen with status stepper (AppRoutes.myShipping).
import 'package:flutter/material.dart';

import '../../core/l10n/l10n.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/status_chip.dart';
import '../../data/models/shipping.dart';
import '../../data/repositories/shipping_repository.dart';

class MyShippingScreen extends StatefulWidget {
  const MyShippingScreen({super.key});

  @override
  State<MyShippingScreen> createState() => _MyShippingScreenState();
}

class _MyShippingScreenState extends State<MyShippingScreen> {
  final _repo = ShippingRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t('itemsMyShippingTitle')),
      ),
      body: AsyncView<List<ShippingRequest>>(
        load: _repo.mine,
        builder: (context, requests, _) {
          if (requests.isEmpty) {
            return ListView(
              children: [
                const SizedBox(height: 80),
                MessageView(
                  icon: Icons.local_shipping_outlined,
                  text: t('itemsShippingEmpty'),
                  actionLabel: t('itemsGoToMyClaims'),
                  onAction: () =>
                      Navigator.pushNamed(context, AppRoutes.myClaims),
                ),
              ],
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) =>
                _ShippingCard(request: requests[index]),
          );
        },
      ),
    );
  }
}

class _ShippingCard extends StatelessWidget {
  const _ShippingCard({required this.request});

  final ShippingRequest request;

  @override
  Widget build(BuildContext context) {
    final hasCarrier =
        request.carrier != null && request.carrier!.trim().isNotEmpty;
    final hasTracking = request.trackingNumber != null &&
        request.trackingNumber!.trim().isNotEmpty;
    final hasAdminNote =
        request.adminNote != null && request.adminNote!.trim().isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.local_shipping_outlined,
                  color: AppColors.govGreen,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${t('itemsShippingOrderPrefix')} #${request.shippingId}',
                        style: const TextStyle(
                          color: AppColors.govGreen,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (request.itemName.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          request.itemName,
                          style: const TextStyle(
                            color: AppColors.textColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                StatusChip(
                  status: request.status,
                  label: request.statusLabel,
                ),
              ],
            ),
            const Divider(height: 22, color: AppColors.borderColor),
            _ShippingMetaRow(
              icon: Icons.location_on_outlined,
              label: t('itemsLocationLabel'),
              value: '${request.city} — ${request.address}',
            ),
            if (request.phone.isNotEmpty) ...[
              const SizedBox(height: 6),
              _ShippingMetaRow(
                icon: Icons.phone_outlined,
                label: t('itemsShippingPhoneLabel'),
                value: request.phone,
              ),
            ],
            if (hasCarrier) ...[
              const SizedBox(height: 6),
              _ShippingMetaRow(
                icon: Icons.business_outlined,
                label: t('itemsShippingCarrierLabel'),
                value: request.carrier!,
              ),
            ],
            if (hasTracking) ...[
              const SizedBox(height: 6),
              _ShippingMetaRow(
                icon: Icons.qr_code_outlined,
                label: t('itemsShippingTrackingLabel'),
                value: request.trackingNumber!,
              ),
            ],
            if (hasAdminNote) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.govBgLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderColor),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppColors.govGoldBronze,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${t('itemsShippingAdminNoteLabel')}: ${request.adminNote}',
                        style: const TextStyle(
                          color: AppColors.textColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            Text(
              t('itemsShippingStagesTitle'),
              style: const TextStyle(
                color: AppColors.govGreen,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            _ShippingStatusStepper(status: request.status),
          ],
        ),
      ),
    );
  }
}

class _ShippingMetaRow extends StatelessWidget {
  const _ShippingMetaRow({
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
        Icon(icon, size: 16, color: AppColors.muted),
        const SizedBox(width: 6),
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
    );
  }
}

class _ShippingStatusStepper extends StatelessWidget {
  const _ShippingStatusStepper({required this.status});

  final String status;

  static const List<String> _order = [
    'pending',
    'approved',
    'shipped',
    'delivered',
  ];

  @override
  Widget build(BuildContext context) {
    final isRejected = status == 'rejected';
    final currentIndex = _order.indexOf(status);
    final stages = <({String key, String label})>[
      (key: 'pending', label: t('itemsShippingStagePending')),
      (key: 'approved', label: t('itemsShippingStageApproved')),
      (key: 'shipped', label: t('itemsShippingStageShipped')),
      (key: 'delivered', label: t('itemsShippingStageDelivered')),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isRejected)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.dangerSoft,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.danger.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.cancel_outlined,
                  color: AppColors.danger,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t('itemsShippingStageRejected'),
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ...List.generate(stages.length, (index) {
          final stage = stages[index];
          final isLast = index == stages.length - 1;
          final isDone = !isRejected && currentIndex >= index;
          final isCurrent = !isRejected && currentIndex == index;
          final dotColor = isRejected
              ? AppColors.danger
              : isCurrent
                  ? AppColors.govGoldBronze
                  : isDone
                      ? AppColors.success
                      : AppColors.borderColor;

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: isDone
                            ? dotColor.withValues(alpha: 0.16)
                            : AppColors.govBgLight,
                        shape: BoxShape.circle,
                        border: Border.all(color: dotColor, width: 2),
                      ),
                      child: Icon(
                        isDone ? Icons.check : Icons.circle,
                        size: isDone ? 13 : 7,
                        color: dotColor,
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          constraints: const BoxConstraints(minHeight: 20),
                          color: (!isRejected && currentIndex > index)
                              ? AppColors.success
                              : AppColors.borderColor,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 12, top: 2),
                    child: Text(
                      stage.label,
                      style: TextStyle(
                        color: isRejected
                            ? AppColors.muted
                            : isDone
                                ? AppColors.textColor
                                : AppColors.muted,
                        fontSize: 12,
                        fontWeight:
                            isCurrent ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
