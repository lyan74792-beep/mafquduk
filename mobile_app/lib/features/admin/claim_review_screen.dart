// Full claim review screen (AppRoutes.adminClaimReview): item + claimant details, security comparison, approve & reject actions.
import 'package:flutter/material.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/form_section.dart';
import '../../core/widgets/item_card.dart';
import '../../data/models/admin.dart';
import '../../data/repositories/admin_repository.dart';

class ClaimReviewScreen extends StatefulWidget {
  const ClaimReviewScreen({super.key});

  @override
  State<ClaimReviewScreen> createState() => _ClaimReviewScreenState();
}

class _ClaimReviewScreenState extends State<ClaimReviewScreen> {
  final AdminRepository _repo = AdminRepository();
  bool _submitting = false;

  Future<void> _approve(AdminClaim claim) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await _repo.approveClaim(claim.claimId);
      if (!mounted) return;
      showSnack(context, t('adminClaimApprovedSuccess'));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      showSnack(context, errorText(e), isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _promptReject(AdminClaim claim) async {
    if (_submitting) return;
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('adminRejectDialogTitle')),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: t('adminRejectReasonLabel'),
            hintText: t('adminRejectReasonHint'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t('adminCancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t('adminRejectClaimBtn')),
          ),
        ],
      ),
    );
    final reason = reasonController.text.trim();
    reasonController.dispose();

    if (confirmed != true || !mounted) return;

    setState(() => _submitting = true);
    try {
      await _repo.rejectClaim(claim.claimId, reason: reason);
      if (!mounted) return;
      showSnack(context, t('adminClaimRejectedSuccess'));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      showSnack(context, errorText(e), isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final claim = ModalRoute.of(context)!.settings.arguments as AdminClaim;
    final hasQuestion = claim.securityQuestion != null &&
        claim.securityQuestion!.trim().isNotEmpty;
    final matched =
        claim.answerMatches;

    return Scaffold(
      backgroundColor: AppColors.govBgLight,
      appBar: AppBar(
        title: Text(t('adminClaimReviewTitle')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.govGoldBronze),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.verified, color: AppColors.govGreen, size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t('adminVerificationBannerTitle'),
                        style: const TextStyle(
                          color: AppColors.govGreen,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t('adminVerificationBannerSub'),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          FormSection(
            title: t('adminFoundItemSection'),
            children: [
              ItemCard(item: claim.item),
              _InfoRow(
                label: t('adminItemNumberLabel'),
                value: '#${claim.item.id}',
              ),
              _InfoRow(
                label: t('adminItemCategoryLabel'),
                value: tv(claim.item.category),
              ),
              _InfoRow(
                label: t('adminItemLocationLabel'),
                value: tv(claim.item.location),
              ),
            ],
          ),
          FormSection(
            title: t('adminClaimantSection'),
            children: [
              _InfoRow(
                label: t('adminClaimantNameLabel'),
                value: claim.claimantName,
              ),
              _InfoRow(
                label: t('adminClaimantEmailLabel'),
                value: claim.claimantEmail,
              ),
              _InfoRow(
                label: t('adminClaimantPhoneLabel'),
                value: claim.claimantPhone,
              ),
              _InfoRow(
                label: t('adminClaimDateLabel'),
                value: claim.claimDate,
              ),
            ],
          ),
          FormSection(
            title: t('adminClaimDescriptionSection'),
            children: [
              Text(
                claim.claimDescription,
                style: const TextStyle(
                  color: AppColors.textColor,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
          if (hasQuestion)
            FormSection(
              title: t('adminSecurityComparisonTitle'),
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.govBgLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: matched ? AppColors.success : AppColors.danger,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        matched ? Icons.check_circle : Icons.cancel,
                        color: matched ? AppColors.success : AppColors.danger,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          matched
                              ? t('adminAnswerMatched')
                              : t('adminAnswerNotMatched'),
                          style: TextStyle(
                            color:
                                matched ? AppColors.success : AppColors.danger,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _InfoRow(
                  label: t('adminFinderQuestionLabel'),
                  value: claim.securityQuestion ?? '',
                ),
                _InfoRow(
                  label: t('adminCorrectAnswerLabel'),
                  value: claim.correctAnswer ?? '',
                ),
                _InfoRow(
                  label: t('adminClaimantAnswerLabel'),
                  value: (claim.securityAnswer != null &&
                          claim.securityAnswer!.trim().isNotEmpty)
                      ? claim.securityAnswer!
                      : t('adminNoAnswerProvided'),
                ),
              ],
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : () => _approve(claim),
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
                  label: Text(t('adminApproveClaimBtn')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _submitting ? null : () => _promptReject(claim),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                  ),
                  icon: const Icon(Icons.cancel_outlined),
                  label: Text(t('adminRejectClaimBtn')),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: AppColors.textColor,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
