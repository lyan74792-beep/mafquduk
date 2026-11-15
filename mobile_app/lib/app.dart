import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/l10n/l10n.dart';
import 'core/routes/app_routes.dart';
import 'core/session/session.dart';
import 'core/theme/app_theme.dart';
import 'features/admin/admin_home_screen.dart';
import 'features/admin/claim_review_screen.dart';
import 'features/admin/manual_match_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/otp_screen.dart';
import 'features/auth/register_admin_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/claims/matches_screen.dart';
import 'features/claims/my_claims_screen.dart';
import 'features/home/user_home_screen.dart';
import 'features/items/browse_items_screen.dart';
import 'features/items/claim_item_screen.dart';
import 'features/items/item_details_screen.dart';
import 'features/items/items_map_screen.dart';
import 'features/notifications/notifications_screen.dart';
import 'features/onboarding/welcome_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/reports/emergency_report_screen.dart';
import 'features/reports/found_report_screen.dart';
import 'features/reports/lost_report_screen.dart';
import 'features/reports/my_reports_screen.dart';
import 'features/reports/track_report_screen.dart';
import 'features/reports/voice_report_screen.dart';
import 'features/shipping/my_shipping_screen.dart';
import 'features/shipping/shipping_request_screen.dart';

/// Root widget: theme, language/direction, and the route table.
class MafqoodakApp extends StatefulWidget {
  const MafqoodakApp({super.key});

  /// Every screen of the app, by route name (see AppRoutes).
  static final Map<String, WidgetBuilder> routes = {
    AppRoutes.welcome: (_) => const WelcomeScreen(),
    AppRoutes.login: (_) => const LoginScreen(),
    AppRoutes.otp: (_) => const OtpScreen(),
    AppRoutes.register: (_) => const RegisterScreen(),
    AppRoutes.registerAdmin: (_) => const RegisterAdminScreen(),
    AppRoutes.home: (_) => const UserHomeScreen(),
    AppRoutes.profile: (_) => const ProfileScreen(),
    AppRoutes.notifications: (_) => const NotificationsScreen(),
    AppRoutes.lostReport: (_) => const LostReportScreen(),
    AppRoutes.foundReport: (_) => const FoundReportScreen(),
    AppRoutes.emergencyReport: (_) => const EmergencyReportScreen(),
    AppRoutes.voiceReport: (_) => const VoiceReportScreen(),
    AppRoutes.myReports: (_) => const MyReportsScreen(),
    AppRoutes.trackReport: (_) => const TrackReportScreen(),
    AppRoutes.browseItems: (_) => const BrowseItemsScreen(),
    AppRoutes.itemDetails: (_) => const ItemDetailsScreen(),
    AppRoutes.claimItem: (_) => const ClaimItemScreen(),
    AppRoutes.map: (_) => const ItemsMapScreen(),
    AppRoutes.matches: (_) => const MatchesScreen(),
    AppRoutes.myClaims: (_) => const MyClaimsScreen(),
    AppRoutes.shippingRequest: (_) => const ShippingRequestScreen(),
    AppRoutes.myShipping: (_) => const MyShippingScreen(),
    AppRoutes.adminHome: (_) => const AdminHomeScreen(),
    AppRoutes.adminClaimReview: (_) => const ClaimReviewScreen(),
    AppRoutes.adminManualMatch: (_) => const ManualMatchScreen(),
  };

  /// First screen: onboarding once, then the dashboard of whoever is logged in.
  static String initialRoute() {
    final session = Session.instance;
    if (!session.welcomeSeen) return AppRoutes.welcome;
    if (!session.isLoggedIn) return AppRoutes.login;
    return session.isAdmin ? AppRoutes.adminHome : AppRoutes.home;
  }

  @override
  State<MafqoodakApp> createState() => _MafqoodakAppState();
}

class _MafqoodakAppState extends State<MafqoodakApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  late bool _wasLoggedIn = Session.instance.isLoggedIn;

  @override
  void initState() {
    super.initState();
    Session.instance.addListener(_onSessionChanged);
    L10n.instance.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    Session.instance.removeListener(_onSessionChanged);
    L10n.instance.removeListener(_onLanguageChanged);
    super.dispose();
  }

  /// The server rejected the token (expired/revoked): go back to login from anywhere
  /// and say why. A normal logout navigates by itself and shows no message.
  void _onSessionChanged() {
    final session = Session.instance;
    if (_wasLoggedIn && !session.isLoggedIn && session.endedByServer) {
      _navigatorKey.currentState?.pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
      _messengerKey.currentState?.showSnackBar(SnackBar(content: Text(t('sessionExpired'))));
    }
    _wasLoggedIn = session.isLoggedIn;
  }

  /// Screens read their texts with t('key'), which is not an inherited
  /// dependency: an open screen (and every const widget in it) would keep the
  /// old language. Mark every element dirty so the whole tree rebuilds with the
  /// new texts; widget state (forms, scroll position, navigation) is kept.
  void _onLanguageChanged() {
    void rebuild(Element element) {
      element.markNeedsBuild();
      element.visitChildren(rebuild);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(rebuild);
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild everything when the language changes (texts + RTL/LTR).
    return ListenableBuilder(
      listenable: L10n.instance,
      builder: (context, _) => MaterialApp(
        navigatorKey: _navigatorKey,
        scaffoldMessengerKey: _messengerKey,
        debugShowCheckedModeBanner: false,
        onGenerateTitle: (_) => t('appName'),
        theme: buildAppTheme(),
        locale: Locale(L10n.instance.lang),
        supportedLocales: L10n.supported.map(Locale.new),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        initialRoute: MafqoodakApp.initialRoute(),
        routes: MafqoodakApp.routes,
      ),
    );
  }
}
