// Urgent missing person / elderly / child report screen (AppRoutes.emergencyReport). Works for guests too.
import 'package:flutter/material.dart';

import '../../core/l10n/l10n.dart';
import '../../core/network/api_exception.dart';
import '../../core/session/session.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/form_section.dart';
import '../../core/widgets/image_pick_field.dart';
import '../../core/widgets/picked_image.dart';
import '../../core/widgets/voice_input_button.dart';
import '../../data/models/lookups.dart';
import '../../data/repositories/lookup_repository.dart';
import '../../data/repositories/report_repository.dart';
import 'widgets/location_fields.dart';
import 'widgets/report_success_dialog.dart';

class EmergencyReportScreen extends StatefulWidget {
  const EmergencyReportScreen({super.key});

  @override
  State<EmergencyReportScreen> createState() => _EmergencyReportScreenState();
}

class _EmergencyReportScreenState extends State<EmergencyReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = ReportRepository();
  final _lookupRepo = LookupRepository();
  final _location = LocationValue();
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _clothingController;
  late final TextEditingController _phoneController;

  PickedImage? _photo;
  bool _submitting = false;
  Map<String, String> _fieldErrors = const {};

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _ageController = TextEditingController();
    _clothingController = TextEditingController();
    final initialPhone = '${Session.instance.profile['phone'] ?? ''}';
    _phoneController = TextEditingController(text: initialPhone);
  }

  @override
  void dispose() {
    _location.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _clothingController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _clearFieldError(String key) {
    if (_fieldErrors.containsKey(key)) {
      setState(() {
        _fieldErrors = Map<String, String>.from(_fieldErrors)..remove(key);
      });
    }
  }

  Future<void> _submit() async {
    setState(() => _fieldErrors = const {});
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _submitting = true);
    try {
      final reportId = await _repo.createEmergency(
        personName: _nameController.text,
        approxAge: _ageController.text,
        lastSeenLocation: _location.landmark,
        locationOther: _location.other,
        clothing: _clothingController.text,
        phone: _phoneController.text,
        photo: _photo,
      );
      if (!mounted) return;
      final nav = Navigator.of(context);
      await showReportSuccessDialog(
        context,
        reportId: reportId,
        title: t('reportsEmergencySuccessTitle'),
        body: t('reportsEmergencyFieldTeamAlerted'),
        isEmergency: true,
      );
      nav.pop(true);
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
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t('reportsEmergencyTitle')),
      ),
      body: AsyncView<Lookups>(
        load: _lookupRepo.load,
        builder: (context, lookups, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              // re-check a field as soon as the user edits it (clears stale errors)
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.dangerSoft,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.danger),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.danger,
                          size: 30,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t('reportsEmergencyBannerTitle'),
                                style: const TextStyle(
                                  color: AppColors.danger,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                t('reportsEmergencyBannerSub'),
                                style: const TextStyle(
                                  color: AppColors.textColor,
                                  fontSize: 12,
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
                    title: t('reportsEmergencyPersonSection'),
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: t('reportsPersonNameOptionalLabel'),
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                        forceErrorText: _fieldErrors['person_name'],
                        onChanged: (_) => _clearFieldError('person_name'),
                      ),
                      TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: t('approxAgeLabel'),
                          hintText: t('reportsApproxAgeHint'),
                          prefixIcon: const Icon(Icons.cake_outlined),
                        ),
                        forceErrorText: _fieldErrors['approx_age'],
                        validator: requiredField,
                        onChanged: (_) => _clearFieldError('approx_age'),
                      ),
                      LocationFields(
                        controller: _location,
                        landmarks: lookups.landmarks,
                        label: t('lastSeenLocationLabel'),
                        showMapPicker: false,
                        errorText: _fieldErrors['last_seen_location'],
                        otherErrorText: _fieldErrors['location_other'],
                        onChanged: () {
                          _clearFieldError('last_seen_location');
                          _clearFieldError('location_other');
                        },
                      ),
                      TextFormField(
                        controller: _clothingController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: t('clothingDescLabel'),
                          hintText: t('reportsClothingHint'),
                          prefixIcon: const Icon(Icons.checkroom_outlined),
                          suffixIcon: VoiceInputButton(controller: _clothingController),
                        ),
                        forceErrorText: _fieldErrors['clothing_description'],
                        validator: requiredField,
                        onChanged: (_) => _clearFieldError('clothing_description'),
                      ),
                    ],
                  ),
                  FormSection(
                    title: t('reportsContactSection'),
                    children: [
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: t('reporterPhoneLabel'),
                          hintText: t('reportsPhoneHint'),
                          prefixIcon: const Icon(Icons.phone_outlined),
                        ),
                        forceErrorText: _fieldErrors['reporter_phone'],
                        validator: phoneValidator,
                        onChanged: (_) => _clearFieldError('reporter_phone'),
                      ),
                    ],
                  ),
                  FormSection(
                    title: t('reportsPhotoSection'),
                    children: [
                      ImagePickField(
                        label: t('reportsEmergencyPhotoLabel'),
                        value: _photo,
                        onChanged: (img) => setState(() => _photo = img),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                    ),
                    onPressed: _submitting ? null : _submit,
                    icon: _submitting
                        ? const SizedBox.shrink()
                        : const Icon(Icons.crisis_alert_outlined),
                    label: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(t('sendEmergencyButton')),
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
