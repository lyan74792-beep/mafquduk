import 'package:flutter/material.dart';

import '../../core/l10n/l10n.dart';
import '../../core/network/api_exception.dart';
import '../../core/routes/app_routes.dart';
import '../../core/session/session.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/server_address_dialog.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/language_menu.dart';
import '../../data/repositories/auth_repository.dart';

/// User and admin sign-in screen with role switch, OTP login link,
/// registration links, and guest shortcuts.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _authRepo = AuthRepository();

  bool _asAdmin = false;
  bool _obscurePassword = true;
  bool _submitting = false;
  Map<String, String> _fieldErrors = const {};

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _fieldErrors = const {});
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      await _authRepo.login(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        asAdmin: _asAdmin,
      );
      if (!mounted) return;
      final dest = Session.instance.isAdmin ? AppRoutes.adminHome : AppRoutes.home;
      Navigator.pushNamedAndRemoveUntil(context, dest, (_) => false);
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
        title: Text(t('title')),
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
                  // Long-press the logo to change the server address (demo on a real phone).
                  GestureDetector(
                    onLongPress: () => showServerAddressDialog(context),
                    child: const Icon(
                      Icons.verified_user,
                      size: 56,
                      color: AppColors.govGoldBronze,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    t('header'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.govGreen,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SegmentedButton<bool>(
                    segments: [
                      ButtonSegment<bool>(
                        value: false,
                        label: Text(t('user')),
                        icon: const Icon(Icons.person),
                      ),
                      ButtonSegment<bool>(
                        value: true,
                        label: Text(t('admin')),
                        icon: const Icon(Icons.admin_panel_settings),
                      ),
                    ],
                    selected: {_asAdmin},
                    onSelectionChanged: (sel) {
                      setState(() {
                        _asAdmin = sel.first;
                        _fieldErrors = const {};
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    validator: emailValidator,
                    forceErrorText: _fieldErrors['email'],
                    decoration: InputDecoration(
                      labelText: t('authEmailLabel'),
                      prefixIcon: const Icon(Icons.email_outlined, color: AppColors.govGreen),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscurePassword,
                    validator: requiredField,
                    forceErrorText: _fieldErrors['password'],
                    decoration: InputDecoration(
                      labelText: t('passwordLabel'),
                      prefixIcon: const Icon(Icons.lock_outline, color: AppColors.govGreen),
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
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(_asAdmin ? t('loginAdmin') : t('loginUser')),
                  ),
                  if (!_asAdmin) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _submitting ? null : () => Navigator.pushNamed(context, AppRoutes.otp),
                      icon: const Icon(Icons.sms_outlined, size: 18),
                      label: Text(t('authLoginWithOtp')),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
                    child: Text(
                      t('authCreateUserAccount'),
                      style: const TextStyle(
                        color: AppColors.govGreen,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.registerAdmin),
                    child: Text(
                      t('authCreateAdminAccount'),
                      style: const TextStyle(
                        color: AppColors.govGoldBronze,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Divider(),
                  TextButton.icon(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.emergencyReport),
                    icon: const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 18),
                    label: Text(
                      t('authEmergencyGuestLink'),
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.trackReport),
                    icon: const Icon(Icons.manage_search_rounded, color: AppColors.govGreen, size: 18),
                    label: Text(
                      t('authTrackReportLink'),
                      style: const TextStyle(
                        color: AppColors.govGreen,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
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
