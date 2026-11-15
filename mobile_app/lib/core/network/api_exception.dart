/// Error returned by the API ({"ok":false,"error":{...}}) or a network failure.
class ApiException implements Exception {
  const ApiException({
    required this.status,
    required this.code,
    required this.message,
    this.fields = const {},
  });

  /// HTTP status; 0 when the server could not be reached.
  final int status;

  /// Machine code from the API: validation, unauthorized, not_found, conflict, network, …
  final String code;

  /// Arabic message, safe to show to the user.
  final String message;

  /// Per-field validation messages (e.g. {'email': '...'}).
  final Map<String, String> fields;

  bool get isNetwork => status == 0;
  bool get isUnauthorized => status == 401;

  @override
  String toString() => message;
}
