// Found item or sighting report screen (AppRoutes.foundReport; argument: bool sighting).
import 'package:flutter/material.dart';

import '../../core/l10n/l10n.dart';
import '../../core/network/api_exception.dart';
import '../../core/routes/app_routes.dart';
import '../../core/session/session.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/date_field.dart';
import '../../core/widgets/form_section.dart';
import '../../core/widgets/image_pick_field.dart';
import '../../core/widgets/lookup_dropdown.dart';
import '../../core/widgets/picked_image.dart';
import '../../core/widgets/voice_input_button.dart';
import '../../data/models/lookups.dart';
import '../../data/repositories/lookup_repository.dart';
import '../../data/repositories/report_repository.dart';
import 'widgets/location_fields.dart';
import 'widgets/report_success_dialog.dart';

class FoundReportScreen extends StatefulWidget {
  const FoundReportScreen({super.key, this.sighting = false});

  final bool sighting;

  @override
  State<FoundReportScreen> createState() => _FoundReportScreenState();
}

class _FoundReportScreenState extends State<FoundReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = ReportRepository();
  final _lookupRepo = LookupRepository();
  final _location = LocationValue();
  late final TextEditingController _descController;
  late final TextEditingController _phoneController;
  late final TextEditingController _questionController;
  late final TextEditingController _answerController;

  String? _category;
  String? _currentStatus;
  DateTime? _date = DateTime.now();
  PickedImage? _image;
  bool _sighting = false;
  bool _submitting = false;
  Map<String, String> _fieldErrors = const {};

  @override
  void initState() {
    super.initState();
    _sighting = widget.sighting;
    _descController = TextEditingController();
    _phoneController = TextEditingController(text: '${Session.instance.profile['phone'] ?? ''}');
    _questionController = TextEditingController();
    _answerController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is bool) _sighting = arg;
  }

  @override
  void dispose() {
    _location.dispose();
    _descController.dispose();
    _phoneController.dispose();
    _questionController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  void _clearFieldError(String key) {
    if (_fieldErrors.containsKey(key)) {
      setState(() => _fieldErrors = Map<String, String>.from(_fieldErrors)..remove(key));
    }
  }

  String? _securityValidator(String? _) {
    final q = _questionController.text.trim();
    final a = _answerController.text.trim();
    if ((q.isEmpty && a.isEmpty) || (q.isNotEmpty && a.isNotEmpty)) return null;
    return t('reportsSecurityBothRequired');
  }

  Future<void> _submit(Lookups lookups) async {
    setState(() => _fieldErrors = const {});
    final effectiveStatus = _sighting && lookups.foundCurrentStatuses.isNotEmpty
        ? lookups.foundCurrentStatuses.last
        : _currentStatus;
    if (!(_formKey.currentState?.validate() ?? false) ||
        _date == null ||
        _category == null ||
        effectiveStatus == null) {
      return;
    }

    setState(() => _submitting = true);
    try {
      final created = await _repo.createFound(
        category: _category!,
        landmark: _location.landmark,
        landmarkOther: _location.other,
        lat: _location.lat,
        lng: _location.lng,
        date: _date!,
        currentStatus: effectiveStatus,
        description: _descController.text,
        phone: _phoneController.text,
        sighting: _sighting,
        securityQuestion: _questionController.text,
        securityAnswer: _answerController.text,
        image: _image,
      );
      if (!mounted) return;
      final nav = Navigator.of(context);
      final action = await showReportSuccessDialog(
        context,
        reportId: created.id,
        matchesFound: created.matchesFound,
        title: t('reportsFoundSuccessTitle'),
        body: t('reportsFoundSuccessBody'),
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
    final isSighting = _sighting;
    return Scaffold(
      appBar: AppBar(
        title: Text(isSighting ? t('reportsSightingTitle') : t('reportsFoundTitle')),
      ),
      body: AsyncView<Lookups>(
        load: _lookupRepo.load,
        builder: (context, lookups, _) {
          final statuses = lookups.foundCurrentStatuses;
          final effectiveStatus =
              isSighting && statuses.isNotEmpty ? statuses.last : _currentStatus;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              // re-check a field as soon as the user edits it (clears stale errors)
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _IntroBanner(isSighting: isSighting),
                  const SizedBox(height: 14),
                  FormSection(
                    title: t('reportsItemSection'),
                    children: [
                      LookupDropdown(
                        label: t('reportsCategoryLabel'),
                        options: lookups.categories,
                        value: _category,
                        icon: Icons.category_outlined,
                        validator: (v) => _fieldErrors['item_category'] ?? requiredField(v),
                        onChanged: (v) {
                          setState(() => _category = v);
                          _clearFieldError('item_category');
                        },
                      ),
                      IgnorePointer(
                        ignoring: isSighting,
                        child: LookupDropdown(
                          label: t('reportsCurrentStatusLabel'),
                          options: statuses,
                          value: effectiveStatus,
                          icon: isSighting ? Icons.lock_outline : Icons.place_outlined,
                          validator: (v) => _fieldErrors['current_status'] ?? requiredField(v),
                          onChanged: (v) {
                            if (!isSighting) {
                              setState(() => _currentStatus = v);
                              _clearFieldError('current_status');
                            }
                          },
                        ),
                      ),
                      if (isSighting)
                        Text(
                          t('reportsSightingStatusLockedHint'),
                          style: const TextStyle(color: AppColors.muted, fontSize: 11),
                        ),
                      TextFormField(
                        controller: _descController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: t('reportsDescriptionLabel'),
                          hintText: t('reportsDescriptionHint'),
                          prefixIcon: const Icon(Icons.description_outlined),
                          suffixIcon: VoiceInputButton(controller: _descController),
                        ),
                        forceErrorText: _fieldErrors['item_description'],
                        validator: requiredField,
                        onChanged: (_) => _clearFieldError('item_description'),
                      ),
                    ],
                  ),
                  FormSection(
                    title: t('reportsWhereWhenSection'),
                    children: [
                      LocationFields(
                        controller: _location,
                        landmarks: lookups.landmarks,
                        label: t('reportsFoundLocationLabel'),
                        errorText: _fieldErrors['found_location'],
                        otherErrorText: _fieldErrors['found_location_other'],
                        onChanged: () {
                          _clearFieldError('found_location');
                          _clearFieldError('found_location_other');
                        },
                      ),
                      DateField(
                        label: t('reportsFoundDateLabel'),
                        value: _date,
                        onChanged: (d) {
                          setState(() => _date = d);
                          _clearFieldError('found_date');
                        },
                      ),
                      if (_fieldErrors['found_date'] != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            _fieldErrors['found_date']!,
                            style: const TextStyle(color: AppColors.danger, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                  FormSection(
                    title: t('reportsSecuritySection'),
                    children: [
                      Text(
                        t('reportsSecurityHint'),
                        style: const TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                      TextFormField(
                        controller: _questionController,
                        decoration: InputDecoration(
                          labelText: t('reportsSecurityQuestionLabel'),
                          hintText: t('reportsSecurityQuestionHint'),
                          prefixIcon: const Icon(Icons.help_outline),
                        ),
                        forceErrorText: _fieldErrors['security_question'],
                        validator: _securityValidator,
                        onChanged: (_) => _clearFieldError('security_question'),
                      ),
                      TextFormField(
                        controller: _answerController,
                        decoration: InputDecoration(
                          labelText: t('reportsSecurityAnswerLabel'),
                          prefixIcon: const Icon(Icons.verified_user_outlined),
                        ),
                        forceErrorText: _fieldErrors['security_answer'],
                        validator: _securityValidator,
                        onChanged: (_) => _clearFieldError('security_answer'),
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
                          labelText: t('reportsFinderPhoneLabel'),
                          hintText: t('reportsPhoneHint'),
                          prefixIcon: const Icon(Icons.phone_outlined),
                        ),
                        forceErrorText: _fieldErrors['finder_phone'],
                        validator: phoneValidator,
                        onChanged: (_) => _clearFieldError('finder_phone'),
                      ),
                    ],
                  ),
                  FormSection(
                    title: t('reportsPhotoSection'),
                    children: [
                      ImagePickField(
                        label: t('attachImageOptional'),
                        value: _image,
                        onChanged: (img) => setState(() => _image = img),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ElevatedButton(
                    onPressed: _submitting ? null : () => _submit(lookups),
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            isSighting
                                ? t('reportsSightingSubmitButton')
                                : t('reportsFoundSubmitButton'),
                          ),
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

class _IntroBanner extends StatelessWidget {
  const _IntroBanner({required this.isSighting});

  final bool isSighting;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSighting ? AppColors.govGoldBronze.withValues(alpha: 0.12) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSighting ? AppColors.govGoldBronze : AppColors.borderColor,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isSighting ? Icons.visibility_outlined : Icons.info_outline,
            color: isSighting ? AppColors.govGoldBronze : AppColors.govGreen,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isSighting ? t('reportsSightingIntro') : t('reportsFoundIntro'),
              style: const TextStyle(color: AppColors.textColor, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
