// Postal shipping request form screen for an approved claim (AppRoutes.shippingRequest).
import 'package:flutter/material.dart';

import '../../core/l10n/l10n.dart';
import '../../core/network/api_exception.dart';
import '../../core/session/session.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/form_section.dart';
import '../../core/widgets/item_card.dart';
import '../../data/models/claim.dart';
import '../../data/repositories/shipping_repository.dart';

class ShippingRequestScreen extends StatefulWidget {
  const ShippingRequestScreen({super.key});

  @override
  State<ShippingRequestScreen> createState() => _ShippingRequestScreenState();
}

class _ShippingRequestScreenState extends State<ShippingRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = ShippingRepository();
  late final TextEditingController _cityController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  late final TextEditingController _notesController;

  bool _submitting = false;
  Map<String, String> _fieldErrors = const {};

  @override
  void initState() {
    super.initState();
    _cityController = TextEditingController();
    _addressController = TextEditingController();
    final initialPhone = '${Session.instance.profile['phone'] ?? ''}';
    _phoneController = TextEditingController(text: initialPhone);
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _cityController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _clearFieldError(String key) {
    if (_fieldErrors.containsKey(key)) {
      setState(() {
        _fieldErrors = Map<String, String>.from(_fieldErrors)..remove(key);
      });
    }
  }

  Future<void> _submit(Claim claim) async {
    setState(() => _fieldErrors = const {});
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    try {
      await _repo.create(
        claimId: claim.claimId,
        city: _cityController.text,
        address: _addressController.text,
        phone: _phoneController.text,
        notes: _notesController.text,
      );
      if (!mounted) return;
      showSnack(context, t('itemsShippingCreatedMsg'));
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
    final claim = ModalRoute.of(context)!.settings.arguments as Claim;

    return Scaffold(
      appBar: AppBar(
        title: Text(t('itemsShippingRequestTitle')),
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
              ItemCard(item: claim.item),
              const SizedBox(height: 12),
              FormSection(
                title: t('itemsShippingAddressSection'),
                children: [
                  TextFormField(
                    controller: _cityController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: t('itemsShippingCityLabel'),
                      hintText: t('itemsShippingCityHint'),
                      prefixIcon: const Icon(Icons.location_city_outlined),
                    ),
                    forceErrorText: _fieldErrors['city'],
                    validator: requiredField,
                    onChanged: (_) => _clearFieldError('city'),
                  ),
                  TextFormField(
                    controller: _addressController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: t('itemsShippingDetailAddressLabel'),
                      hintText: t('itemsShippingDetailAddressHint'),
                      prefixIcon: const Icon(Icons.home_outlined),
                    ),
                    forceErrorText: _fieldErrors['address'],
                    validator: requiredField,
                    onChanged: (_) => _clearFieldError('address'),
                  ),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: t('itemsShippingPhoneLabel'),
                      hintText: t('itemsShippingPhoneHint'),
                      prefixIcon: const Icon(Icons.phone_outlined),
                    ),
                    forceErrorText: _fieldErrors['phone'],
                    validator: phoneValidator,
                    onChanged: (_) => _clearFieldError('phone'),
                  ),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: t('itemsShippingNotesLabel'),
                      hintText: t('itemsShippingNotesHint'),
                      prefixIcon: const Icon(Icons.notes_outlined),
                    ),
                    forceErrorText: _fieldErrors['notes'],
                    onChanged: (_) => _clearFieldError('notes'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ElevatedButton.icon(
                onPressed: _submitting ? null : () => _submit(claim),
                icon: _submitting
                    ? const SizedBox.shrink()
                    : const Icon(Icons.local_shipping_outlined),
                label: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(t('itemsShippingSubmitButton')),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
