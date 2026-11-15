import 'package:flutter/material.dart';

import '../../core/l10n/l10n.dart';
import '../../core/routes/app_routes.dart';
import '../../core/session/session.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/language_menu.dart';
import '../../data/repositories/notification_repository.dart';

/// Main visitor home dashboard with a personalized welcome card and a
/// responsive grid of service cards (2 columns on phones, 4 when width >= 700).
class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  final _notificationRepo = NotificationRepository();
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    if (!Session.instance.isLoggedIn) return;
    try {
      final page = await _notificationRepo.list();
      if (mounted) {
        setState(() => _unreadCount = page.unreadCount);
      }
    } catch (_) {
      // Silently ignore badge refresh errors on the home dashboard.
    }
  }

  Future<void> _openNotifications() async {
    await Navigator.pushNamed(context, AppRoutes.notifications);
    await _loadUnreadCount();
  }

  Future<void> _openProfile() async {
    await Navigator.pushNamed(context, AppRoutes.profile);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final name = Session.instance.displayName.trim();
    final welcomeTitle =
        name.isNotEmpty ? '${t('authWelcomeUserPrefix')} $name' : t('welcomeHeader');
    final isWide = MediaQuery.of(context).size.width >= 700;

    return Scaffold(
      backgroundColor: AppColors.govBgLight,
      appBar: AppBar(
        title: Text(t('appName')),
        actions: [
          const LanguageMenu(),
          IconButton(
            tooltip: t('authNotificationsTooltip'),
            onPressed: _openNotifications,
            icon: Badge(
              isLabelVisible: _unreadCount > 0,
              label: Text('$_unreadCount'),
              backgroundColor: AppColors.danger,
              child: const Icon(Icons.notifications_outlined, color: AppColors.govGreen),
            ),
          ),
          IconButton(
            tooltip: t('authProfileTooltip'),
            onPressed: _openProfile,
            icon: const Icon(Icons.person_outline, color: AppColors.govGreen),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: Column(
                children: [
                  const Icon(Icons.shield_rounded, size: 44, color: AppColors.govGreen),
                  const SizedBox(height: 8),
                  Text(
                    welcomeTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.govGreen,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    t('welcomeSubtitle'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              t('mainServicesHeader'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.govGreen,
              ),
            ),
            const SizedBox(height: 12),
            GridView(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isWide ? 4 : 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                mainAxisExtent: 150,
              ),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _SquareServiceCard(
                  icon: Icons.search_rounded,
                  title: t('authSvcLostTitle'),
                  subtitle: t('authSvcLostSub'),
                  onTap: () => Navigator.pushNamed(context, AppRoutes.lostReport),
                ),
                _SquareServiceCard(
                  icon: Icons.inventory_2_outlined,
                  title: t('authSvcFoundTitle'),
                  subtitle: t('authSvcFoundSub'),
                  onTap: () => Navigator.pushNamed(context, AppRoutes.foundReport, arguments: false),
                ),
                _SquareServiceCard(
                  icon: Icons.visibility_outlined,
                  title: t('authSvcSightingTitle'),
                  subtitle: t('authSvcSightingSub'),
                  onTap: () => Navigator.pushNamed(context, AppRoutes.foundReport, arguments: true),
                ),
                _SquareServiceCard(
                  icon: Icons.warning_amber_rounded,
                  title: t('authSvcEmergencyTitle'),
                  subtitle: t('authSvcEmergencySub'),
                  isEmergency: true,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.emergencyReport),
                ),
                _SquareServiceCard(
                  icon: Icons.mic_none_rounded,
                  title: t('authSvcVoiceTitle'),
                  subtitle: t('authSvcVoiceSub'),
                  onTap: () => Navigator.pushNamed(context, AppRoutes.voiceReport),
                ),
                _SquareServiceCard(
                  icon: Icons.grid_view_rounded,
                  title: t('authSvcBrowseTitle'),
                  subtitle: t('authSvcBrowseSub'),
                  onTap: () => Navigator.pushNamed(context, AppRoutes.browseItems),
                ),
                _SquareServiceCard(
                  icon: Icons.map_outlined,
                  title: t('authSvcMapTitle'),
                  subtitle: t('authSvcMapSub'),
                  onTap: () => Navigator.pushNamed(context, AppRoutes.map),
                ),
                _SquareServiceCard(
                  icon: Icons.fact_check_outlined,
                  title: t('authSvcMyReportsTitle'),
                  subtitle: t('authSvcMyReportsSub'),
                  onTap: () => Navigator.pushNamed(context, AppRoutes.myReports),
                ),
                _SquareServiceCard(
                  icon: Icons.compare_arrows_rounded,
                  title: t('authSvcMatchesTitle'),
                  subtitle: t('authSvcMatchesSub'),
                  onTap: () => Navigator.pushNamed(context, AppRoutes.matches),
                ),
                _SquareServiceCard(
                  icon: Icons.assignment_turned_in_outlined,
                  title: t('authSvcClaimsTitle'),
                  subtitle: t('authSvcClaimsSub'),
                  onTap: () => Navigator.pushNamed(context, AppRoutes.myClaims),
                ),
                _SquareServiceCard(
                  icon: Icons.local_shipping_outlined,
                  title: t('authSvcShippingTitle'),
                  subtitle: t('authSvcShippingSub'),
                  onTap: () => Navigator.pushNamed(context, AppRoutes.myShipping),
                ),
                _SquareServiceCard(
                  icon: Icons.manage_search_rounded,
                  title: t('authSvcTrackTitle'),
                  subtitle: t('authSvcTrackSub'),
                  onTap: () => Navigator.pushNamed(context, AppRoutes.trackReport),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SquareServiceCard extends StatelessWidget {
  const _SquareServiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isEmergency = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isEmergency;

  @override
  Widget build(BuildContext context) {
    final accentColor = isEmergency ? AppColors.danger : AppColors.govGreen;
    final actionColor = isEmergency ? AppColors.danger : AppColors.govGoldBronze;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEmergency ? AppColors.danger : AppColors.borderColor,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: accentColor, size: 22),
                const SizedBox(height: 4),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 10),
                ),
              ],
            ),
            SizedBox(
              width: double.infinity,
              height: 26,
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: onTap,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      t('authStartService'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: actionColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
