import 'package:flutter/material.dart';

import '../../core/l10n/l10n.dart';
import '../../core/routes/app_routes.dart';
import '../../core/session/session.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/language_menu.dart';

/// Onboarding welcome screen with brand shield, tagline, feature highlights,
/// and quick guest actions for emergency reporting and report tracking.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  Future<void> _start(BuildContext context) async {
    await Session.instance.markWelcomeSeen();
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.govBgLight,
      appBar: AppBar(
        title: Text(t('appName')),
        actions: const [LanguageMenu()],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.borderColor),
                      ),
                      child: const Icon(
                        Icons.shield_rounded,
                        size: 80,
                        color: AppColors.govGreen,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    t('authBrandTitle'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: AppColors.govGreenDark,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    t('authWelcomeTagline'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.muted,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 36),
                  Wrap(
                    alignment: WrapAlignment.spaceAround,
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _FeatureItem(
                        icon: Icons.security_rounded,
                        label: t('authFeatureSecurity'),
                      ),
                      _FeatureItem(
                        icon: Icons.verified_user_rounded,
                        label: t('authFeatureOwnership'),
                      ),
                      _FeatureItem(
                        icon: Icons.lock_outline_rounded,
                        label: t('authFeaturePrivacy'),
                      ),
                      _FeatureItem(
                        icon: Icons.auto_awesome_rounded,
                        label: t('authFeatureSmartMatch'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () => _start(context),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(t('authStartApp')),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextButton.icon(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.emergencyReport),
                    icon: const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 20),
                    label: Text(
                      t('authEmergencyNoAccount'),
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.trackReport),
                    icon: const Icon(Icons.manage_search_rounded, color: AppColors.govGreen, size: 20),
                    label: Text(
                      t('authTrackReportBtn'),
                      style: const TextStyle(
                        color: AppColors.govGreen,
                        fontWeight: FontWeight.w700,
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

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.govGoldBronze, size: 28),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.govGreenDark,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
