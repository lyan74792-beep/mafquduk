import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../l10n/l10n.dart';
import 'api_exception.dart';

/// A file to send in a multipart request (works on mobile and web).
class UploadFile {
  const UploadFile({required this.field, required this.bytes, required this.filename});

  final String field;
  final Uint8List bytes;
  final String filename;
}

/// Thin wrapper around the Mafqoodak REST API.
///
/// Every call returns the `data` object of {"ok":true,"data":{...}}
/// or throws [ApiException].
class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  final http.Client _http = http.Client();

  /// Bearer token of the logged-in user/admin (set by Session).
  String? token;

  /// Called when the server rejects the token (expired / revoked).
  void Function()? onUnauthorized;

  Future<Map<String, dynamic>> get(String path, {Map<String, String>? query}) {
    return _send(() => _http.get(_uri(path, query), headers: _headers()));
  }

  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body}) {
    return _send(() => _http.post(_uri(path), headers: _headers(json: true), body: jsonEncode(body ?? {})));
  }

  Future<Map<String, dynamic>> put(String path, {Map<String, dynamic>? body}) {
    return _send(() => _http.put(_uri(path), headers: _headers(json: true), body: jsonEncode(body ?? {})));
  }

  /// multipart/form-data: text [fields] plus optional [files].
  Future<Map<String, dynamic>> multipart(
    String path, {
    required Map<String, String> fields,
    List<UploadFile> files = const [],
  }) {
    return _send(() async {
      final request = http.MultipartRequest('POST', _uri(path))
        ..headers.addAll(_headers())
        ..fields.addAll(fields);
      for (final f in files) {
        request.files.add(http.MultipartFile.fromBytes(f.field, f.bytes, filename: f.filename));
      }
      return http.Response.fromStream(await _http.send(request));
    });
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final clean = path.startsWith('/') ? path.substring(1) : path;
    final uri = Uri.parse('${ApiConfig.baseUrl}$clean');
    final q = <String, String>{...?query}..removeWhere((_, v) => v.isEmpty);
    return q.isEmpty ? uri : uri.replace(queryParameters: q);
  }

  Map<String, String> _headers({bool json = false}) => {
        'Accept': 'application/json',
        // server messages come back in the app's language
        'Accept-Language': L10n.instance.lang,
        if (json) 'Content-Type': 'application/json; charset=utf-8',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<Map<String, dynamic>> _send(Future<http.Response> Function() call) async {
    final http.Response res;
    try {
      res = await call().timeout(ApiConfig.timeout);
    } on TimeoutException {
      throw ApiException(status: 0, code: 'network', message: t('networkTimeout'));
    } on http.ClientException {
      throw ApiException(status: 0, code: 'network', message: t('networkUnreachable'));
    }

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } on FormatException {
      throw ApiException(status: res.statusCode, code: 'bad_response', message: t('badServerResponse'));
    }

    if (body['ok'] == true) {
      final data = body['data'];
      return data is Map<String, dynamic> ? data : <String, dynamic>{};
    }

    final error = (body['error'] as Map?)?.cast<String, dynamic>() ?? const {};
    final fields = (error['fields'] as Map?)?.map((k, v) => MapEntry('$k', '$v')) ?? const <String, String>{};
    final ex = ApiException(
      status: res.statusCode,
      code: '${error['code'] ?? 'error'}',
      message: '${error['message'] ?? t('unexpectedError')}',
      fields: fields,
    );
    if (ex.isUnauthorized && token != null) {
      onUnauthorized?.call();
    }
    throw ex;
  }
}
