import 'package:flutter/material.dart';

import '../../core/l10n/l10n.dart';
import '../../core/network/api_exception.dart';
import '../../core/routes/app_routes.dart';
import '../../core/session/session.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/form_section.dart';
import '../../core/widgets/language_menu.dart';
import '../../data/repositories/auth_repository.dart';

/// User profile screen with header avatar card, personal details form,
/// password change form, language selector, and red outlined logout button.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _nationalityCtrl = TextEditingController();
  final _currentPwCtrl = TextEditingController();
  final _newPwCtrl = TextEditingController();
  final _confirmPwCtrl = TextEditingController();
  final _authRepo = AuthRepository();

  bool _savingProfile = false;
  bool _savingPassword = false;
  bool _loggingOut = false;
  Map<String, String> _profileErrors = const {};
  Map<String, String> _pwErrors = const {};

  @override
  void initState() {
    super.initState();
    final p = Session.instance.profile;
    _nameCtrl.text = '${p['full_name'] ?? ''}';
    _phoneCtrl.text = '${p['phone'] ?? ''}';
    _nationalityCtrl.text = '${p['nationality'] ?? ''}';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _nationalityCtrl.dispose();
    _currentPwCtrl.dispose();
    _newPwCtrl.dispose();
    _confirmPwCtrl.dispose();
    super.dispose();
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return '${parts.first.characters.first}${parts.last.characters.first}'.toUpperCase();
  }

  String? _optionalPhoneValidator(String? v) {
    final text = v?.trim() ?? '';
    if (text.isEmpty) return null;
    return phoneValidator(text);
  }

  String? _confirmPwValidator(String? v) {
    final req = requiredField(v);
    if (req != null) return req;
    if (v != _newPwCtrl.text) return t('authPasswordMismatch');
    return null;
  }

  Future<void> _saveProfile() async {
    setState(() => _profileErrors = const {});
    if (!_profileFormKey.currentState!.validate()) return;

    setState(() => _savingProfile = true);
    try {
      await _authRepo.updateProfile(
        fullName: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        nationality: _nationalityCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() {});
      showSnack(context, t('authProfileSavedMsg'));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _profileErrors = e.fields);
      showSnack(context, errorText(e), isError: true);
    } catch (e) {
      if (!mounted) return;
      showSnack(context, errorText(e), isError: true);
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  Future<void> _changePassword() async {
    setState(() => _pwErrors = const {});
    if (!_passwordFormKey.currentState!.validate()) return;

    setState(() => _savingPassword = true);
    try {
      await _authRepo.changePassword(
        current: _currentPwCtrl.text,
        newPassword: _newPwCtrl.text,
      );
      if (!mounted) return;
      _currentPwCtrl.clear();
      _newPwCtrl.clear();
      _confirmPwCtrl.clear();
      showSnack(context, t('authPasswordChangedMsg'));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _pwErrors = e.fields);
      showSnack(context, errorText(e), isError: true);
    } catch (e) {
      if (!mounted) return;
      showSnack(context, errorText(e), isError: true);
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  Future<void> _logout() async {
    setState(() => _loggingOut = true);
    await _authRepo.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final profile = Session.instance.profile;
    final fullName = '${profile['full_name'] ?? _nameCtrl.text}';
    final email = '${profile['email'] ?? ''}';

    return Scaffold(
      backgroundColor: AppColors.govBgLight,
      appBar: AppBar(
        title: Text(t('authProfileTitle')),
        actions: const [LanguageMenu()],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.govGreen,
                          child: Text(
                            _initials(fullName),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          fullName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textColor,
                          ),
                        ),
                        if (email.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: const TextStyle(fontSize: 13, color: AppColors.muted),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Form(
                  key: _profileFormKey,
                  child: FormSection(
                    title: t('authPersonalInfoSection'),
                    children: [
                      TextFormField(
                        controller: _nameCtrl,
                        validator: requiredField,
                        forceErrorText: _profileErrors['full_name'],
                        decoration: InputDecoration(
                          labelText: t('authFullNameLabel'),
                          prefixIcon: const Icon(Icons.person_outline, color: AppColors.govGreen),
                        ),
                      ),
                      TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        validator: _optionalPhoneValidator,
                        forceErrorText: _profileErrors['phone'],
                        decoration: InputDecoration(
                          labelText: t('authPhoneLabel'),
                          hintText: t('authPhoneHint'),
                          prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.govGreen),
                        ),
                      ),
                      TextFormField(
                        controller: _nationalityCtrl,
                        forceErrorText: _profileErrors['nationality'],
                        decoration: InputDecoration(
                          labelText: t('authNationalityLabel'),
                          prefixIcon: const Icon(Icons.public_outlined, color: AppColors.govGreen),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _savingProfile ? null : _saveProfile,
                        child: _savingProfile
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(t('authSaveProfileBtn')),
                      ),
                    ],
                  ),
                ),
                Form(
                  key: _passwordFormKey,
                  child: FormSection(
                    title: t('authChangePasswordSection'),
                    children: [
                      TextFormField(
                        controller: _currentPwCtrl,
                        obscureText: true,
                        validator: requiredField,
                        forceErrorText: _pwErrors['current_password'],
                        decoration: InputDecoration(
                          labelText: t('authCurrentPasswordLabel'),
                          prefixIcon: const Icon(Icons.lock_outline, color: AppColors.govGreen),
                        ),
                      ),
                      TextFormField(
                        controller: _newPwCtrl,
                        obscureText: true,
                        validator: minLength(8),
                        forceErrorText: _pwErrors['new_password'],
                        decoration: InputDecoration(
                          labelText: t('authNewPasswordLabel'),
                          prefixIcon: const Icon(Icons.lock_reset_outlined, color: AppColors.govGreen),
                        ),
                      ),
                      TextFormField(
                        controller: _confirmPwCtrl,
                        obscureText: true,
                        validator: _confirmPwValidator,
                        decoration: InputDecoration(
                          labelText: t('authConfirmPasswordLabel'),
                          prefixIcon: const Icon(Icons.verified_user_outlined, color: AppColors.govGreen),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _savingPassword ? null : _changePassword,
                        child: _savingPassword
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(t('authUpdatePasswordBtn')),
                      ),
                    ],
                  ),
                ),
                FormSection(
                  title: t('authLanguageSection'),
                  children: [
                    for (final code in L10n.supported)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.language, color: AppColors.govGoldBronze),
                        title: Text(
                          L10n.names[code] ?? code,
                          style: TextStyle(
                            fontWeight: L10n.instance.lang == code ? FontWeight.w700 : FontWeight.w500,
                            color: L10n.instance.lang == code ? AppColors.govGreen : AppColors.textColor,
                          ),
                        ),
                        trailing: L10n.instance.lang == code
                            ? const Icon(Icons.check_circle_rounded, color: AppColors.govGreen)
                            : null,
                        onTap: () async {
                          await L10n.instance.setLanguage(code);
                          if (mounted) setState(() {});
                        },
                      ),
                  ],
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                  ),
                  onPressed: _loggingOut ? null : _logout,
                  icon: const Icon(Icons.logout_rounded),
                  label: Text(t('authLogoutBtn')),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
