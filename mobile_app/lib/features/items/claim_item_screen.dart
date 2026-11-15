// Ownership claim submission screen for a found item (AppRoutes.claimItem).
import 'package:flutter/material.dart';

import '../../core/l10n/l10n.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/form_section.dart';
import '../../core/widgets/voice_input_button.dart';
import '../../data/models/item_summary.dart';
import '../../data/repositories/claim_repository.dart';

class ClaimItemScreen extends StatefulWidget {
  const ClaimItemScreen({super.key});

  @override
  State<ClaimItemScreen> createState() => _ClaimItemScreenState();
}

class _ClaimItemScreenState extends State<ClaimItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = ClaimRepository();
  late final TextEditingController _descController;
  late final TextEditingController _answerController;

  bool _submitting = false;
  Map<String, String> _fieldErrors = const {};

  @override
  void initState() {
    super.initState();
    _descController = TextEditingController();
    _answerController = TextEditingController();
  }

  @override
  void dispose() {
    _descController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  void _clearFieldError(String key) {
    if (_fieldErrors.containsKey(key)) {
      setState(() {
        _fieldErrors = Map<String, String>.from(_fieldErrors)..remove(key);
      });
    }
  }

  Future<void> _submit(ItemDetails item) async {
    setState(() => _fieldErrors = const {});
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    try {
      final claimId = await _repo.claimItem(
        item.id,
        description: _descController.text,
        securityAnswer: _answerController.text,
      );
      if (!mounted) return;
      final nav = Navigator.of(context);
      await _showSuccessDialog(claimId);
      nav.pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.fields.isNotEmpty) {
        setState(() => _fieldErrors = e.fields);
      }
      showSnack(context, errorText(e), isError: true);
    } catch (e) {
      if (!mounted) return;
      showSnack(context, errorText(e), isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _showSuccessDialog(int claimId) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: AppColors.success),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                t('itemsClaimSuccessTitle'),
                style: const TextStyle(
                  color: AppColors.govGreen,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t('itemsClaimSuccessBody'),
              style: const TextStyle(color: AppColors.textColor, fontSize: 13),
            ),
            if (claimId > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.govBgLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      t('itemsClaimIdLabel'),
                      style: const TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                    Text(
                      '#$claimId',
                      style: const TextStyle(
                        color: AppColors.govGreen,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(t('itemsClaimDoneButton')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = ModalRoute.of(context)!.settings.arguments as ItemDetails;
    final hasQuestion =
        item.securityQuestion != null && item.securityQuestion!.trim().isNotEmpty;
    final displayTitle = item.itemName.isNotEmpty ? item.itemName : tv(item.category);

    return Scaffold(
      appBar: AppBar(
        title: Text(t('itemsClaimTitle')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          // re-check a field as soon as the user edits it (clears stale errors)
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Explanation banner card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderColor),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.verified_user,
                      color: AppColors.govGoldBronze,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t('itemsClaimVerifyBannerTitle'),
                            style: const TextStyle(
                              color: AppColors.govGreen,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            t('itemsClaimVerifyBannerSub'),
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FormSection(
                title: t('itemsClaimItemSummarySection'),
                children: [
                  _SummaryRow(
                    label: t('itemsClaimReportIdLabel'),
                    value: '#${item.id}',
                  ),
                  const Divider(height: 1, color: AppColors.borderColor),
                  _SummaryRow(
                    label: t('itemsCategoryLabel'),
                    value: displayTitle,
                  ),
                  if (item.location.isNotEmpty) ...[
                    const Divider(height: 1, color: AppColors.borderColor),
                    _SummaryRow(
                      label: t('itemsLocationLabel'),
                      value: tv(item.location),
                    ),
                  ],
                ],
              ),
              FormSection(
                title: t('itemsClaimProofSection'),
                children: [
                  TextFormField(
                    controller: _descController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: t('itemsClaimDescLabel'),
                      hintText: t('itemsClaimDescHint'),
                      prefixIcon: const Icon(Icons.fact_check_outlined),
                      suffixIcon: VoiceInputButton(controller: _descController),
                    ),
                    forceErrorText: _fieldErrors['claim_description'],
                    validator: minLength(10),
                    onChanged: (_) => _clearFieldError('claim_description'),
                  ),
                ],
              ),
              if (hasQuestion)
                FormSection(
                  title: t('itemsClaimSecuritySection'),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.govBgLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.borderColor),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.help_outline,
                            color: AppColors.govGoldBronze,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${t('itemsClaimSecurityQuestionPrefix')} ${item.securityQuestion}',
                              style: const TextStyle(
                                color: AppColors.govGreenDark,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextFormField(
                      controller: _answerController,
                      decoration: InputDecoration(
                        labelText: t('itemsClaimSecurityAnswerLabel'),
                        hintText: t('itemsClaimSecurityAnswerHint'),
                        prefixIcon: const Icon(Icons.key_outlined),
                      ),
                      forceErrorText: _fieldErrors['security_answer'],
                      validator: requiredField,
                      onChanged: (_) => _clearFieldError('security_answer'),
                    ),
                  ],
                ),
              const SizedBox(height: 4),
              ElevatedButton.icon(
                onPressed: _submitting ? null : () => _submit(item),
                icon: _submitting
                    ? const SizedBox.shrink()
                    : const Icon(Icons.send_outlined),
                label: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(t('itemsClaimSubmitButton')),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.muted, fontSize: 13),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: AppColors.textColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
