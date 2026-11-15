import '../../core/network/api_client.dart';
import '../../core/session/session.dart';
import '../models/account.dart';

/// Accounts: login, registration, OTP, profile (docs/API.md "auth" + "/me").
///
/// Repositories are the only place that knows API paths and JSON keys;
/// screens call these methods and get typed results or an ApiException.
class AuthRepository {
  AuthRepository({ApiClient? api, Session? session})
      : _api = api ?? ApiClient.instance,
        _session = session ?? Session.instance;

  final ApiClient _api;
  final Session _session;

  Future<void> login({required String email, required String password, required bool asAdmin}) async {
    final data = await _api.post('auth/login', body: {
      'email': email,
      'password': password,
      'account_type': asAdmin ? 'admin' : 'user',
    });
    await _session.start(data);
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final data = await _api.post('auth/register', body: {
      'full_name': fullName,
      'email': email,
      'password': password,
      'confirm_password': confirmPassword,
    });
    await _session.start(data);
  }

  /// Returns the server's message (the account waits for approval).
  Future<String> registerAdmin({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final data = await _api.post('auth/register-admin', body: {
      'full_name': fullName,
      'email': email,
      'password': password,
      'confirm_password': confirmPassword,
    });
    return '${data['message'] ?? ''}';
  }

  Future<OtpRequestResult> requestOtp(String phone) async {
    final data = await _api.post('auth/otp/request', body: {'phone': phone});
    return OtpRequestResult(
      expiresIn: (data['expires_in'] as num?)?.toInt() ?? 300,
      debugCode: data['debug_code'] as String?,
    );
  }

  Future<void> verifyOtp({required String phone, required String code}) async {
    final data = await _api.post('auth/otp/verify', body: {'phone': phone, 'code': code});
    await _session.start(data);
  }

  Future<void> logout() async {
    try {
      await _api.post('auth/logout');
    } finally {
      await _session.clear(); // log out locally even if the server is unreachable
    }
  }

  Future<AppUser> updateProfile({required String fullName, String phone = '', String nationality = ''}) async {
    final data = await _api.put('me', body: {'full_name': fullName, 'phone': phone, 'nationality': nationality});
    final user = (data['user'] as Map).cast<String, dynamic>();
    await _session.updateProfile(user);
    return AppUser.fromJson(user);
  }

  Future<void> changePassword({required String current, required String newPassword}) {
    return _api.post('me/password', body: {'current_password': current, 'new_password': newPassword});
  }
}
