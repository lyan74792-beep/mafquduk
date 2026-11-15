/// A visitor account (API object "User").
class AppUser {
  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.nationality,
    this.accountStatus,
  });

  final int id;
  final String fullName;
  final String email;
  final String? phone;
  final String? nationality;
  final String? accountStatus;

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: (j['user_id'] as num).toInt(),
        fullName: '${j['full_name'] ?? ''}',
        email: '${j['email'] ?? ''}',
        phone: j['phone'] as String?,
        nationality: j['nationality'] as String?,
        accountStatus: j['account_status'] as String?,
      );
}

/// Result of POST /auth/otp/request.
class OtpRequestResult {
  const OtpRequestResult({required this.expiresIn, this.debugCode});

  final int expiresIn;

  /// Only present while no SMS provider is configured (development).
  final String? debugCode;
}
