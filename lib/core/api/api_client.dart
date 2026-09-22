import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_exception.dart';
import 'token_store.dart';

/// Thin wrapper around `package:http` that speaks the Callit API's
/// envelope: every response is `{"data": ...}` on success or
/// `{"error": {"code","message","fields"}}` on failure. Callers get back
/// the decoded `data` payload (or `null` for an empty body) and never
/// see the envelope itself; failures surface as [ApiException].
///
/// Adds the bearer JWT automatically whenever [TokenStore] holds one, so
/// the per-endpoint service methods never touch headers.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final base = Uri.parse(ApiConfig.baseUrl);
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    final segments = [...base.pathSegments, ...cleanPath.split('/')].where((s) => s.isNotEmpty).toList();
    final q = <String, String>{};
    query?.forEach((k, v) {
      if (v == null) return;
      q[k] = v.toString();
    });
    return base.replace(pathSegments: segments, queryParameters: q.isEmpty ? null : q);
  }

  Map<String, String> _headers({bool auth = true}) {
    final headers = {'Content-Type': 'application/json', 'Accept': 'application/json'};
    final token = TokenStore.instance.token;
    if (auth && token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query, bool auth = true}) {
    return _send(() => http.get(_uri(path, query), headers: _headers(auth: auth)));
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body, bool auth = true}) {
    return _send(() => http.post(_uri(path), headers: _headers(auth: auth), body: jsonEncode(body ?? {})));
  }

  Future<dynamic> _send(Future<http.Response> Function() call) async {
    http.Response res;
    try {
      res = await call().timeout(ApiConfig.timeout);
    } on SocketException {
      throw ApiException(statusCode: 0, code: 'NETWORK_ERROR', message: 'Could not reach the Callit server. Check your connection and try again.');
    } on HttpException {
      throw ApiException(statusCode: 0, code: 'NETWORK_ERROR', message: 'Could not reach the Callit server.');
    } catch (_) {
      throw ApiException(statusCode: 0, code: 'NETWORK_ERROR', message: 'The request timed out. Please try again.');
    }

    Map<String, dynamic>? decoded;
    if (res.body.isNotEmpty) {
      try {
        final parsed = jsonDecode(res.body);
        if (parsed is Map<String, dynamic>) decoded = parsed;
      } catch (_) {
        // Non-JSON body (e.g. an HTML error page from a proxy) — fall
        // through and raise a generic error below.
      }
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return decoded?['data'];
    }

    final error = decoded?['error'] as Map<String, dynamic>?;
    final fieldsRaw = error?['fields'] as Map<String, dynamic>?;
    throw ApiException(
      statusCode: res.statusCode,
      code: (error?['code'] as String?) ?? 'HTTP_${res.statusCode}',
      message: (error?['message'] as String?) ?? 'Something went wrong (${res.statusCode}).',
      fields: fieldsRaw?.map((k, v) => MapEntry(k, (v as List).map((e) => e.toString()).toList())),
    );
  }
}
