import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/l10n/l10n.dart';
import '../../core/network/api_exception.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/language_menu.dart';
import '../../data/repositories/auth_repository.dart';

/// Two-step phone OTP sign-in screen:
/// Step 1 requests an OTP for a registered 05XXXXXXXX phone number;
/// Step 2 verifies the 4-digit code with a 60-second resend countdown.
class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _phoneFormKey = GlobalKey<FormState>();
  final _codeFormKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _authRepo = AuthRepository();

  bool _codeSent = false;
  bool _submitting = false;
  String? _debugCode;
  int _resendSeconds = 0;
  Timer? _timer;
  Map<String, String> _fieldErrors = const {};

  @override
  void dispose() {
    _timer?.cancel();
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _resendSeconds = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendSeconds <= 1) {
        timer.cancel();
        setState(() => _resendSeconds = 0);
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  Future<void> _requestOtp() async {
    setState(() => _fieldErrors = const {});
    if (!_codeSent && !_phoneFormKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      final result = await _authRepo.requestOtp(_phoneCtrl.text.trim());
      if (!mounted) return;
      setState(() {
        _codeSent = true;
        _debugCode = result.debugCode;
      });
      _startCountdown();
      showSnack(context, t('otpSentMsg'));
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

  Future<void> _verifyOtp() async {
    setState(() => _fieldErrors = const {});
    if (!_codeFormKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      await _authRepo.verifyOtp(
        phone: _phoneCtrl.text.trim(),
        code: _codeCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
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

  String? _codeValidator(String? v) {
    final text = v?.trim() ?? '';
    if (text.isEmpty) return t('fieldRequired');
    if (!RegExp(r'^[0-9]{4}$').hasMatch(text)) return t('authOtpCodeInvalid');
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.govBgLight,
      appBar: AppBar(
        title: Text(t('authOtpScreenTitle')),
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
            child: _codeSent ? _buildStep2() : _buildStep1(),
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Form(
      key: _phoneFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.phone_android_rounded, size: 64, color: AppColors.govGreen),
          const SizedBox(height: 16),
          Text(
            t('authOtpStep1Title'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.govGreen,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t('authOtpStep1Sub'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            validator: phoneValidator,
            forceErrorText: _fieldErrors['phone'],
            decoration: InputDecoration(
              labelText: t('authPhoneLabel'),
              hintText: t('authPhoneHint'),
              prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.govGreen),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _submitting ? null : _requestOtp,
            child: _submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(t('authRequestOtpBtn')),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Form(
      key: _codeFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.mark_email_read_outlined, size: 64, color: AppColors.govGreen),
          const SizedBox(height: 16),
          Text(
            t('authOtpStep2Title'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.govGreen,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${t('authOtpStep2Sub')}\n${_phoneCtrl.text.trim()}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          if (_debugCode != null && _debugCode!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.govBgLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.govGoldBronze, width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.govGoldBronze),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${t('otpDevNotice')} $_debugCode',
                      style: const TextStyle(
                        color: AppColors.govGreenDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          TextFormField(
            controller: _codeCtrl,
            keyboardType: TextInputType.number,
            maxLength: 4,
            textAlign: TextAlign.center,
            validator: _codeValidator,
            forceErrorText: _fieldErrors['code'],
            style: const TextStyle(fontSize: 22, letterSpacing: 8, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              labelText: t('authOtpCodeLabel'),
              counterText: '',
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _submitting ? null : _verifyOtp,
            child: _submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(t('authVerifyOtpBtn')),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: (_submitting || _resendSeconds > 0) ? null : _requestOtp,
            child: Text(
              _resendSeconds > 0
                  ? '${t('authResendIn')} $_resendSeconds ${t('authSecondsUnit')}'
                  : t('resendOtp'),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _submitting
                ? null
                : () {
                    _timer?.cancel();
                    setState(() {
                      _codeSent = false;
                      _codeCtrl.clear();
                      _fieldErrors = const {};
                    });
                  },
            child: Text(t('authChangePhone')),
          ),
        ],
      ),
    );
  }
}
