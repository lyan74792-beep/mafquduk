import 'package:flutter/material.dart';

import '../../core/l10n/l10n.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/language_menu.dart';
import '../../data/repositories/auth_repository.dart';

/// Admin account sign-up screen. Submitting creates a pending admin account,
/// displays the server's confirmation message in a dialog, and pops back to login.
class RegisterAdminScreen extends StatefulWidget {
  const RegisterAdminScreen({super.key});

  @override
  State<RegisterAdminScreen> createState() => _RegisterAdminScreenState();
}

class _RegisterAdminScreenState extends State<RegisterAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _authRepo = AuthRepository();

  bool _obscurePassword = true;
  bool _acceptedTerms = false;
  bool _termsError = false;
  bool _submitting = false;
  Map<String, String> _fieldErrors = const {};

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String? _confirmValidator(String? v) {
    final req = requiredField(v);
    if (req != null) return req;
    if (v != _passwordCtrl.text) return t('authPasswordMismatch');
    return null;
  }

  Future<void> _submit() async {
    setState(() {
      _fieldErrors = const {};
      _termsError = !_acceptedTerms;
    });
    final valid = _formKey.currentState!.validate();
    if (!valid || !_acceptedTerms) return;

    setState(() => _submitting = true);
    try {
      final msg = await _authRepo.registerAdmin(
        fullName: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        confirmPassword: _confirmCtrl.text,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            t('authAdminPendingTitle'),
            style: const TextStyle(color: AppColors.govGreen, fontWeight: FontWeight.w700),
          ),
          content: Text(msg.isNotEmpty ? msg : t('authAdminPendingTitle')),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(t('authOk')),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _fieldErrors = e.fields);
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
      backgroundColor: AppColors.govBgLight,
      appBar: AppBar(
        title: Text(t('authRegisterAdminTitle')),
        actions: const [LanguageMenu()],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Form(
              key: _formKey,
              // re-check a field as soon as the user edits it (clears stale errors)
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.admin_panel_settings,
                    size: 56,
                    color: AppColors.govGoldBronze,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    t('authRegisterAdminHeader'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.govGoldBronze,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameCtrl,
                    validator: requiredField,
                    forceErrorText: _fieldErrors['full_name'],
                    decoration: InputDecoration(
                      labelText: t('authFullNameLabel'),
                      prefixIcon: const Icon(Icons.person_outline, color: AppColors.govGoldBronze),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    validator: emailValidator,
                    forceErrorText: _fieldErrors['email'],
                    decoration: InputDecoration(
                      labelText: t('authAdminEmailLabel'),
                      prefixIcon: const Icon(Icons.email_outlined, color: AppColors.govGoldBronze),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscurePassword,
                    validator: minLength(8),
                    forceErrorText: _fieldErrors['password'],
                    decoration: InputDecoration(
                      labelText: t('passwordLabel'),
                      prefixIcon: const Icon(Icons.lock_outline, color: AppColors.govGoldBronze),
                      suffixIcon: IconButton(
                        tooltip: _obscurePassword ? t('authPasswordShow') : t('authPasswordHide'),
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: AppColors.muted,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmCtrl,
                    obscureText: _obscurePassword,
                    validator: _confirmValidator,
                    forceErrorText: _fieldErrors['confirm_password'],
                    decoration: InputDecoration(
                      labelText: t('authConfirmPasswordLabel'),
                      prefixIcon: const Icon(Icons.lock_reset_outlined, color: AppColors.govGoldBronze),
                    ),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: _acceptedTerms,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: AppColors.govGoldBronze,
                    title: Text(
                      t('authAcceptTerms'),
                      style: const TextStyle(fontSize: 13, color: AppColors.textColor),
                    ),
                    subtitle: _termsError
                        ? Text(
                            t('authTermsRequired'),
                            style: const TextStyle(color: AppColors.danger, fontSize: 12),
                          )
                        : null,
                    onChanged: (v) {
                      setState(() {
                        _acceptedTerms = v ?? false;
                        if (_acceptedTerms) _termsError = false;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.govGoldBronze,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(t('authRegisterAdminSubmit')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
