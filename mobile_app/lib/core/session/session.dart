import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/api_client.dart';

/// Who is logged in (persisted across app restarts).
///
/// Listen to it (ListenableBuilder) to rebuild when the user logs in/out.
class Session extends ChangeNotifier {
  Session._();

  static final Session instance = Session._();

  static const _kToken = 'session_token';
  static const _kRole = 'session_role';
  static const _kProfile = 'session_profile';
  static const _kWelcomeSeen = 'welcome_seen';

  String? _token;
  String? _role; // 'user' | 'admin'
  Map<String, dynamic> _profile = const {};
  bool _welcomeSeen = false;

  bool get isLoggedIn => _token != null;
  bool get isAdmin => _role == 'admin';
  bool get isUser => _role == 'user';
  String? get role => _role;
  bool get welcomeSeen => _welcomeSeen;

  /// The `user` or `admin` object from the API.
  Map<String, dynamic> get profile => _profile;
  String get displayName => '${_profile['full_name'] ?? ''}';

  /// Restore the saved session; call once before runApp.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_kToken);
    _role = prefs.getString(_kRole);
    _welcomeSeen = prefs.getBool(_kWelcomeSeen) ?? false;
    final raw = prefs.getString(_kProfile);
    _profile = raw == null ? const {} : (jsonDecode(raw) as Map<String, dynamic>);
    ApiClient.instance
      ..token = _token
      ..onUnauthorized = expire;
  }

  /// True when the last logout was forced by the server (token expired/revoked),
  /// not chosen by the user. Read by the app shell to show "session ended".
  bool get endedByServer => _endedByServer;
  bool _endedByServer = false;

  /// The server rejected the token: log out and remember why.
  Future<void> expire() async {
    _endedByServer = true;
    await clear();
  }

  /// Store a login result: {token, role, user|admin}.
  Future<void> start(Map<String, dynamic> loginData) async {
    _endedByServer = false;
    _token = loginData['token'] as String;
    _role = loginData['role'] as String;
    _profile = (loginData[_role] as Map).cast<String, dynamic>();
    ApiClient.instance.token = _token;
    await _persist();
    notifyListeners();
  }

  Future<void> updateProfile(Map<String, dynamic> profile) async {
    _profile = profile;
    await _persist();
    notifyListeners();
  }

  Future<void> clear() async {
    _token = null;
    _role = null;
    _profile = const {};
    ApiClient.instance.token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kRole);
    await prefs.remove(_kProfile);
    notifyListeners();
  }

  Future<void> markWelcomeSeen() async {
    _welcomeSeen = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kWelcomeSeen, true);
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken, _token!);
    await prefs.setString(_kRole, _role!);
    await prefs.setString(_kProfile, jsonEncode(_profile));
  }
}
