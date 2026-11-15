// Lost item report screen (AppRoutes.lostReport).
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

class LostReportScreen extends StatefulWidget {
  const LostReportScreen({super.key});

  @override
  State<LostReportScreen> createState() => _LostReportScreenState();
}

class _LostReportScreenState extends State<LostReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = ReportRepository();
  final _lookupRepo = LookupRepository();
  final _location = LocationValue();
  late final TextEditingController _descController;
  late final TextEditingController _phoneController;

  String? _category;
  DateTime? _date = DateTime.now();
  PickedImage? _image;
  bool _submitting = false;
  Map<String, String> _fieldErrors = const {};

  @override
  void initState() {
    super.initState();
    _descController = TextEditingController();
    final initialPhone = '${Session.instance.profile['phone'] ?? ''}';
    _phoneController = TextEditingController(text: initialPhone);
  }

  @override
  void dispose() {
    _location.dispose();
    _descController.dispose();
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
    if (!(_formKey.currentState?.validate() ?? false) || _date == null || _category == null) {
      return;
    }

    setState(() => _submitting = true);
    try {
      final created = await _repo.createLost(
        category: _category!,
        landmark: _location.landmark,
        landmarkOther: _location.other,
        lat: _location.lat,
        lng: _location.lng,
        date: _date!,
        description: _descController.text,
        phone: _phoneController.text,
        image: _image,
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
      if (action == 'matches') {
        nav.pushNamed(AppRoutes.matches);
      }
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
        title: Text(t('reportsLostTitle')),
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
                  Text(
                    t('reportsLostIntro'),
                    style: const TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
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
                        label: t('reportsLostLocationLabel'),
                        errorText: _fieldErrors['lost_location'],
                        otherErrorText: _fieldErrors['lost_location_other'],
                        onChanged: () {
                          _clearFieldError('lost_location');
                          _clearFieldError('lost_location_other');
                        },
                      ),
                      DateField(
                        label: t('reportsLostDateLabel'),
                        value: _date,
                        onChanged: (d) {
                          setState(() => _date = d);
                          _clearFieldError('lost_date');
                        },
                      ),
                      if (_fieldErrors['lost_date'] != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            _fieldErrors['lost_date']!,
                            style: const TextStyle(color: AppColors.danger, fontSize: 12),
                          ),
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
                        label: t('attachImageOptional'),
                        value: _image,
                        onChanged: (img) => setState(() => _image = img),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
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
