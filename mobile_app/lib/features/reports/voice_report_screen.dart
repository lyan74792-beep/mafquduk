// Accessible voice-first lost report screen (AppRoutes.voiceReport).
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../core/l10n/l10n.dart';
import '../../core/network/api_exception.dart';
import '../../core/routes/app_routes.dart';
import '../../core/session/session.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/date_field.dart';
import '../../core/widgets/form_section.dart';
import '../../core/widgets/lookup_dropdown.dart';
import '../../data/models/lookups.dart';
import '../../data/repositories/lookup_repository.dart';
import '../../data/repositories/report_repository.dart';
import 'widgets/location_fields.dart';
import 'widgets/report_success_dialog.dart';

class VoiceReportScreen extends StatefulWidget {
  const VoiceReportScreen({super.key});

  @override
  State<VoiceReportScreen> createState() => _VoiceReportScreenState();
}

class _VoiceReportScreenState extends State<VoiceReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = ReportRepository();
  final _lookupRepo = LookupRepository();
  final _speech = SpeechToText();
  final _location = LocationValue();
  late final TextEditingController _descController;
  late final TextEditingController _phoneController;

  String? _category;
  DateTime _date = DateTime.now();
  bool _listening = false;
  bool _submitting = false;
  Map<String, String> _fieldErrors = const {};

  @override
  void initState() {
    super.initState();
    _descController = TextEditingController();
    _phoneController = TextEditingController(text: '${Session.instance.profile['phone'] ?? ''}');
  }

  @override
  void dispose() {
    _speech.stop();
    _location.dispose();
    _descController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  static String _localeFor(String lang) {
    switch (lang) {
      case 'en':
        return 'en_US';
      case 'tr':
        return 'tr_TR';
      case 'ur':
        return 'ur_PK';
      case 'ar':
      default:
        return 'ar_SA';
    }
  }

  Future<void> _toggleMic() async {
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }

    bool available = false;
    try {
      available = await _speech.initialize(
        onStatus: (status) {
          if ((status == 'done' || status == 'notListening') && mounted) {
            setState(() => _listening = false);
          }
        },
        onError: (_) {
          if (mounted) setState(() => _listening = false);
        },
      );
    } catch (_) {
      available = false;
    }

    if (!available) {
      if (mounted) showSnack(context, t('voiceUnavailable'), isError: true);
      return;
    }

    setState(() => _listening = true);
    await _speech.listen(
      listenOptions: SpeechListenOptions(localeId: _localeFor(L10n.instance.lang)),
      onResult: _onSpeechResult,
    );
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    if (!result.finalResult) return;
    final words = result.recognizedWords.trim();
    if (words.isEmpty) return;
    final existing = _descController.text.trim();
    final updated = existing.isEmpty ? words : '$existing $words';
    _descController.value = TextEditingValue(
      text: updated,
      selection: TextSelection.collapsed(offset: updated.length),
    );
    if (mounted) setState(() => _listening = false);
  }

  Future<void> _submit() async {
    setState(() => _fieldErrors = const {});
    if (!(_formKey.currentState?.validate() ?? false) || _category == null) {
      return;
    }

    setState(() => _submitting = true);
    try {
      final created = await _repo.createLost(
        category: _category!,
        landmark: _location.landmark,
        landmarkOther: _location.other,
        date: _date,
        description: _descController.text,
        phone: _phoneController.text,
      );
      if (!mounted) return;
      final nav = Navigator.of(context);
      final action = await showReportSuccessDialog(
        context,
        reportId: created.id,
        matchesFound: created.matchesFound,
        title: t('reportsLostSuccessTitle'),
        body: t('reportsLostSuccessBody'),
      );
      nav.pop(true);
      if (action == 'matches') nav.pushNamed(AppRoutes.matches);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.fields.isNotEmpty) {
        setState(() => _fieldErrors = e.fields);
        _formKey.currentState?.validate();
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
    return Scaffold(
      appBar: AppBar(title: Text(t('reportsVoiceTitle'))),
      body: AsyncView<Lookups>(
        load: _lookupRepo.load,
        builder: (context, lookups, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Form(
              key: _formKey,
              // re-check a field as soon as the user edits it (clears stale errors)
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _VoiceHeroCard(listening: _listening, onToggle: _toggleMic),
                  const SizedBox(height: 16),
                  FormSection(
                    title: t('reportsVoiceStep1Title'),
                    children: [
                      TextFormField(
                        controller: _descController,
                        maxLines: 4,
                        style: const TextStyle(fontSize: 17, color: AppColors.textColor),
                        decoration: InputDecoration(
                          labelText: t('reportsDescriptionLabel'),
                          hintText: t('reportsDescriptionHint'),
                        ),
                        forceErrorText: _fieldErrors['item_description'],
                        validator: requiredField,
                      ),
                    ],
                  ),
                  FormSection(
                    title: t('reportsVoiceStep2Title'),
                    children: [
                      LookupDropdown(
                        label: t('reportsCategoryLabel'),
                        options: lookups.categories,
                        value: _category,
                        icon: Icons.category_outlined,
                        validator: (v) => _fieldErrors['item_category'] ?? requiredField(v),
                        onChanged: (v) => setState(() => _category = v),
                      ),
                      LocationFields(
                        controller: _location,
                        landmarks: lookups.landmarks,
                        label: t('reportsLostLocationLabel'),
                        showMapPicker: false,
                        errorText: _fieldErrors['lost_location'],
                        otherErrorText: _fieldErrors['lost_location_other'],
                      ),
                    ],
                  ),
                  FormSection(
                    title: t('reportsVoiceStep3Title'),
                    children: [
                      DateField(
                        label: t('reportsLostDateLabel'),
                        value: _date,
                        onChanged: (d) => setState(() => _date = d),
                      ),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(fontSize: 17, color: AppColors.textColor),
                        decoration: InputDecoration(
                          labelText: t('reporterPhoneLabel'),
                          hintText: t('reportsPhoneHint'),
                          prefixIcon: const Icon(Icons.phone_outlined),
                        ),
                        forceErrorText: _fieldErrors['reporter_phone'],
                        validator: phoneValidator,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      textStyle: const TextStyle(
                        fontFamily: AppColors.fontFamily,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onPressed: _submitting ? null : _submit,
                    icon: _submitting
                        ? const SizedBox.shrink()
                        : const Icon(Icons.send_outlined),
                    label: _submitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(t('reportsLostSubmitButton')),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _VoiceHeroCard extends StatelessWidget {
  const _VoiceHeroCard({required this.listening, required this.onToggle});

  final bool listening;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: [
          Text(
            t('reportsVoiceHeaderTitle'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.govGreenDark,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            t('reportsVoiceHeaderSub'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, fontSize: 14),
          ),
          const SizedBox(height: 20),
          Semantics(
            button: true,
            label: listening ? t('stopVoiceInput') : t('voiceInput'),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onToggle,
              child: CircleAvatar(
                radius: 48,
                backgroundColor: listening ? AppColors.danger : AppColors.govGreen,
                child: Icon(
                  listening ? Icons.stop_rounded : Icons.mic_rounded,
                  color: Colors.white,
                  size: 44,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            listening ? t('reportsVoiceListeningNow') : t('reportsVoiceTapToStart'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: listening ? AppColors.danger : AppColors.govGreenDark,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
