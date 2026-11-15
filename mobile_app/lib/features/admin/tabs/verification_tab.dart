// Verification tab: 'Under Review' claims with claimant details, security answer comparison box, and navigation to ClaimReviewScreen.
import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../data/models/admin.dart';
import '../../../data/repositories/admin_repository.dart';

class VerificationTab extends StatefulWidget {
  const VerificationTab({super.key});

  @override
  State<VerificationTab> createState() => _VerificationTabState();
}

class _VerificationTabState extends State<VerificationTab> {
  final AdminRepository _repo = AdminRepository();

  Future<void> _openClaimReview(
    AdminClaim claim,
    Future<void> Function() reload,
  ) async {
    final changed = await Navigator.pushNamed(
      context,
      AppRoutes.adminClaimReview,
      arguments: claim,
    );
    if (changed == true && mounted) {
      await reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AsyncView<List<AdminClaim>>(
      load: () => _repo.claims(status: 'Under Review'),
      isEmpty: (items) => items.isEmpty,
      emptyText: t('adminEmptyVerification'),
      emptyIcon: Icons.verified_user_outlined,
      builder: (context, claims, reload) {
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: claims.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final claim = claims[index];
            return _VerificationClaimCard(
              claim: claim,
              onTap: () => _openClaimReview(claim, reload),
            );
          },
        );
      },
    );
  }
}

class _VerificationClaimCard extends StatelessWidget {
  const _VerificationClaimCard({
    required this.claim,
    required this.onTap,
  });

  final AdminClaim claim;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final itemTitle = claim.item.itemName.isNotEmpty
        ? claim.item.itemName
        : tv(claim.item.category);
    final hasQuestion = claim.securityQuestion != null &&
        claim.securityQuestion!.trim().isNotEmpty;

    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.borderColor),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified_outlined, color: AppColors.govGreen),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$itemTitle (${t('adminClaimIdPrefix')}${claim.claimId})',
                      style: const TextStyle(
                        color: AppColors.govGreen,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  StatusChip(status: claim.status),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${tv(claim.item.category)} · ${tv(claim.item.location)}',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const Divider(height: 20),
              _DetailLine(
                label: t('adminClaimantNameLabel'),
                value: claim.claimantName,
              ),
              if (claim.claimantEmail.isNotEmpty)
                _DetailLine(
                  label: t('adminClaimantEmailLabel'),
                  value: claim.claimantEmail,
                ),
              if (claim.claimantPhone.isNotEmpty)
                _DetailLine(
                  label: t('adminClaimantPhoneLabel'),
                  value: claim.claimantPhone,
                ),
              const SizedBox(height: 8),
              Text(
                t('adminClaimDescriptionSection'),
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                claim.claimDescription,
                style: const TextStyle(
                  color: AppColors.textColor,
                  fontSize: 13,
                ),
              ),
              if (hasQuestion) ...[
                const SizedBox(height: 12),
                _SecurityComparisonBox(claim: claim),
              ],
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: Text(t('adminReviewClaimBtn')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecurityComparisonBox extends StatelessWidget {
  const _SecurityComparisonBox({required this.claim});

  final AdminClaim claim;

  @override
  Widget build(BuildContext context) {
    final matched = claim.answerMatches;
    final matchColor = matched ? AppColors.success : AppColors.danger;
    final claimantAns =
        (claim.securityAnswer != null && claim.securityAnswer!.trim().isNotEmpty)
            ? claim.securityAnswer!
            : t('adminNoAnswerProvided');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.govBgLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: matchColor.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                matched ? Icons.check_circle : Icons.cancel,
                color: matchColor,
                size: 18,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  t('adminSecurityComparisonTitle'),
                  style: const TextStyle(
                    color: AppColors.govGreen,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                matched ? t('adminAnswerMatched') : t('adminAnswerNotMatched'),
                style: TextStyle(
                  color: matchColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _DetailLine(
            label: t('adminFinderQuestionLabel'),
            value: claim.securityQuestion ?? '',
          ),
          _DetailLine(
            label: t('adminCorrectAnswerLabel'),
            value: claim.correctAnswer ?? '',
          ),
          _DetailLine(
            label: t('adminClaimantAnswerLabel'),
            value: claimantAns,
          ),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

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
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
