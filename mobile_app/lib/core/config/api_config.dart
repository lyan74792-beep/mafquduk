import 'package:shared_preferences/shared_preferences.dart';

/// Where the PHP API lives (see docs/API.md).
///
/// Priority: address saved in the app (long-press the logo on the login screen)
/// → `--dart-define=API_BASE_URL=...` at build time → platform default.
class ApiConfig {
  ApiConfig._();

  static const String _buildOverride = String.fromEnvironment('API_BASE_URL');
  static const String _prefsKey = 'api_base_url';
  static String? _savedOverride;

  /// Load the address saved on this device; call once at start-up.
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _savedOverride = prefs.getString(_prefsKey);
  }

  /// Save a server address on this device ('' restores the default).
  static Future<void> save(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final clean = url.trim();
    if (clean.isEmpty) {
      _savedOverride = null;
      await prefs.remove(_prefsKey);
    } else {
      _savedOverride = _normalize(clean);
      await prefs.setString(_prefsKey, _savedOverride!);
    }
  }

  /// The live server (Contabo, https).
  static const String productionBaseUrl = 'https://mafquduk.dev/Project/api/v1/';

  /// Address used when nothing is saved on the device.
  /// For a local XAMPP server, build with
  /// `--dart-define=API_BASE_URL=http://10.0.2.2/Project/api/v1/` (emulator)
  /// or set the address in the app (long-press the login logo).
  static String get defaultBaseUrl {
    if (_buildOverride.isNotEmpty) return _normalize(_buildOverride);
    return productionBaseUrl;
  }

  static String get baseUrl => _savedOverride ?? defaultBaseUrl;

  // Local addresses (localhost, 10.0.2.2, 192.168.x.x ...) have no certificate.
  static final RegExp _localHost =
      RegExp(r'^(localhost|\d{1,3}(\.\d{1,3}){3})(:\d+)?(/|$)');

  /// Accepts "mafquduk.dev", "192.168.1.20", "http://192.168.1.20" or a full
  /// API URL. Without a scheme, local addresses get http and domains https.
  static String _normalize(String url) {
    var u = url;
    if (!u.startsWith('http://') && !u.startsWith('https://')) {
      u = _localHost.hasMatch(u) ? 'http://$u' : 'https://$u';
    }
    if (!u.contains('/api/v1')) {
      u = u.endsWith('/') ? '${u}Project/api/v1/' : '$u/Project/api/v1/';
    }
    return u.endsWith('/') ? u : '$u/';
  }

  static const Duration timeout = Duration(seconds: 20);
}
