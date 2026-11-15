// Main admin dashboard shell with AppBar actions (LanguageMenu, logout) and 7 feature tabs.
import 'package:flutter/material.dart';

import '../../core/l10n/l10n.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/language_menu.dart';
import '../../data/repositories/auth_repository.dart';
import 'tabs/admins_tab.dart';
import 'tabs/emergencies_tab.dart';
import 'tabs/handover_tab.dart';
import 'tabs/overview_tab.dart';
import 'tabs/reports_tab.dart';
import 'tabs/shipping_tab.dart';
import 'tabs/verification_tab.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final AuthRepository _authRepo = AuthRepository();
  bool _loggingOut = false;

  Future<void> _logout() async {
    if (_loggingOut) return;
    setState(() => _loggingOut = true);
    try {
      await _authRepo.logout();
    } finally {
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (_) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: L10n.instance,
      builder: (context, _) {
        return DefaultTabController(
          length: 7,
          child: Scaffold(
            backgroundColor: AppColors.govBgLight,
            appBar: AppBar(
              title: Text(t('adminDashboardTitle')),
              actions: [
                const LanguageMenu(),
                IconButton(
                  tooltip: t('adminLogoutTooltip'),
                  onPressed: _loggingOut ? null : _logout,
                  icon: _loggingOut
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.logout, color: AppColors.danger),
                ),
                const SizedBox(width: 4),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(52),
                child: Container(
                  color: Colors.white,
                  child: TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelColor: AppColors.govGreen,
                    unselectedLabelColor: AppColors.muted,
                    indicatorColor: AppColors.govGoldBronze,
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(
                      fontFamily: AppColors.fontFamily,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontFamily: AppColors.fontFamily,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                    tabs: [
                      Tab(
                        icon: const Icon(Icons.dashboard_outlined, size: 18),
                        text: t('adminTabOverview'),
                      ),
                      Tab(
                        icon: const Icon(
                          Icons.warning_amber_rounded,
                          size: 18,
                          color: AppColors.danger,
                        ),
                        text: t('adminTabEmergencies'),
                      ),
                      Tab(
                        icon: const Icon(Icons.folder_open_outlined, size: 18),
                        text: t('adminTabReports'),
                      ),
                      Tab(
                        icon: const Icon(Icons.verified_user_outlined, size: 18),
                        text: t('adminTabVerification'),
                      ),
                      Tab(
                        icon: const Icon(Icons.inventory_2_outlined, size: 18),
                        text: t('adminTabHandover'),
                      ),
                      Tab(
                        icon: const Icon(Icons.local_shipping_outlined, size: 18),
                        text: t('adminTabShipping'),
                      ),
                      Tab(
                        icon: const Icon(
                          Icons.admin_panel_settings_outlined,
                          size: 18,
                        ),
                        text: t('adminTabAdmins'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            body: const TabBarView(
              children: [
                OverviewTab(),
                EmergenciesTab(),
                ReportsTab(),
                VerificationTab(),
                HandoverTab(),
                ShippingTab(),
                AdminsTab(),
              ],
            ),
          ),
        );
      },
    );
  }
}
