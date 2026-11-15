/// Named routes for every screen. Screens navigate with
/// `Navigator.pushNamed(context, AppRoutes.x, arguments: ...)` and never
/// import each other, so the navigation map lives in one place (lib/app.dart).
class AppRoutes {
  AppRoutes._();

  // onboarding + auth
  static const welcome = '/welcome';
  static const login = '/login';
  static const otp = '/otp';
  static const register = '/register';
  static const registerAdmin = '/register-admin';

  // visitor
  static const home = '/home';
  static const profile = '/profile';
  static const lostReport = '/reports/lost';
  /// arguments: `bool` — true opens the form as a sighting report
  static const foundReport = '/reports/found';
  static const emergencyReport = '/reports/emergency';
  /// accessible voice-first lost report
  static const voiceReport = '/reports/voice';
  static const myReports = '/reports/mine';
  static const trackReport = '/reports/track';
  static const browseItems = '/items';
  /// arguments: `ItemSummary`
  static const itemDetails = '/items/details';
  /// arguments: `ItemDetails`
  static const claimItem = '/items/claim';
  static const map = '/map';
  static const matches = '/matches';
  static const myClaims = '/claims';
  /// arguments: `Claim`
  static const shippingRequest = '/shipping/new';
  static const myShipping = '/shipping/mine';
  static const notifications = '/notifications';

  // admin
  static const adminHome = '/admin';
  /// arguments: `AdminClaim`
  static const adminClaimReview = '/admin/claim';
  static const adminManualMatch = '/admin/match';
}
