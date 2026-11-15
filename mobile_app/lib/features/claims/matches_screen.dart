// Suggested matches screen where the user can claim or reject matches (AppRoutes.matches).
import 'package:flutter/material.dart';

import '../../core/l10n/l10n.dart';
import '../../core/network/api_exception.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/item_card.dart';
import '../../core/widgets/voice_input_button.dart';
import '../../data/models/claim.dart';
import '../../data/repositories/claim_repository.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  final _repo = ClaimRepository();

  Future<void> _onClaimMatch(
    BuildContext context,
    MatchSuggestion match,
    Future<void> Function() reload,
  ) async {
    final claimed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _ClaimMatchSheet(match: match, repo: _repo),
    );
    if (claimed == true && context.mounted) {
      showSnack(context, t('itemsMatchClaimSubmitted'));
      await reload();
    }
  }

  Future<void> _onRejectMatch(
    BuildContext context,
    MatchSuggestion match,
    Future<void> Function() reload,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          t('itemsMatchRejectTitle'),
          style: const TextStyle(
            color: AppColors.govGreen,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          t('itemsMatchRejectBody'),
          style: const TextStyle(color: AppColors.textColor, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(t('itemsMatchCancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              minimumSize: const Size(0, 40),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(t('itemsMatchRejectConfirm')),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    try {
      await _repo.rejectMatch(match.matchId);
      if (!context.mounted) return;
      showSnack(context, t('itemsMatchRejectedMsg'));
      await reload();
    } catch (e) {
      if (!context.mounted) return;
      showSnack(context, errorText(e), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t('itemsMatchesTitle')),
      ),
      body: AsyncView<List<MatchSuggestion>>(
        load: _repo.matches,
        isEmpty: (list) => list.isEmpty,
        emptyText: t('itemsMatchesEmpty'),
        emptyIcon: Icons.compare_arrows_outlined,
        builder: (context, matches, reload) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: matches.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    t('itemsMatchesIntro'),
                    style: const TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                );
              }
              final match = matches[index - 1];
              final pct = match.score.clamp(0, 100).round();
              final ratio = (match.score / 100).clamp(0.0, 1.0);

              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome_outlined,
                            size: 18,
                            color: AppColors.govGoldBronze,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${t('itemsMatchScoreLabel')}: $pct%',
                            style: const TextStyle(
                              color: AppColors.govGreen,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${t('itemsMatchLostReportRef')} #${match.lostItemId}',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 8,
                          backgroundColor: AppColors.govBgLight,
                          color: pct >= 70
                              ? AppColors.success
                              : AppColors.govGoldBronze,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ItemCard(
                        item: match.found,
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.itemDetails,
                          arguments: match.found,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _onClaimMatch(context, match, reload),
                              icon: const Icon(
                                Icons.verified_user_outlined,
                                size: 18,
                              ),
                              label: Text(t('itemsMatchThisIsMine')),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.danger,
                                side: const BorderSide(color: AppColors.danger),
                              ),
                              onPressed: () =>
                                  _onRejectMatch(context, match, reload),
                              icon: const Icon(Icons.close, size: 18),
                              label: Text(t('itemsMatchNotMine')),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ClaimMatchSheet extends StatefulWidget {
  const _ClaimMatchSheet({required this.match, required this.repo});

  final MatchSuggestion match;
  final ClaimRepository repo;

  @override
  State<_ClaimMatchSheet> createState() => _ClaimMatchSheetState();
}

class _ClaimMatchSheetState extends State<_ClaimMatchSheet> {
  final _formKey = GlobalKey<FormState>();
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

  Future<void> _submit() async {
    setState(() => _fieldErrors = const {});
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    try {
      await widget.repo.claimMatch(
        widget.match.matchId,
        description: _descController.text,
        securityAnswer: _answerController.text,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
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

  @override
  Widget build(BuildContext context) {
    final question = widget.match.securityQuestion;
    final hasQuestion = question != null && question.trim().isNotEmpty;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 20, 16, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          // re-check a field as soon as the user edits it (clears stale errors)
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                t('itemsMatchClaimSheetTitle'),
                style: const TextStyle(
                  color: AppColors.govGreen,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                t('itemsMatchClaimSheetSub'),
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: t('itemsClaimDescLabel'),
                  hintText: t('itemsClaimDescHint'),
                  prefixIcon: const Icon(Icons.fact_check_outlined),
                  suffixIcon: VoiceInputButton(controller: _descController),
                ),
                forceErrorText: _fieldErrors['claim_description'],
                validator: minLength(10),
              ),
              if (hasQuestion) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.govBgLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderColor),
                  ),
                  child: Text(
                    '${t('itemsClaimSecurityQuestionPrefix')} $question',
                    style: const TextStyle(
                      color: AppColors.govGreenDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _answerController,
                  decoration: InputDecoration(
                    labelText: t('itemsClaimSecurityAnswerLabel'),
                    hintText: t('itemsClaimSecurityAnswerHint'),
                    prefixIcon: const Icon(Icons.key_outlined),
                  ),
                  forceErrorText: _fieldErrors['security_answer'],
                  validator: requiredField,
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
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
            ],
          ),
        ),
      ),
    );
  }
}
