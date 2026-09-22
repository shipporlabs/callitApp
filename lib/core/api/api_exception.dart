/// The Callit API's error envelope, thrown by [ApiClient] on any non-2xx
/// response or a decode failure: `{"error": {"code","message","fields"}}`.
class ApiException implements Exception {
  ApiException({required this.statusCode, required this.code, required this.message, this.fields});

  final int statusCode;
  final String code;
  final String message;
  final Map<String, List<String>>? fields;

  /// True for the network-only case (no server, no signal, timed out) —
  /// worth a different message than a real 4xx/5xx from the server.
  bool get isNetworkError => statusCode == 0;

  @override
  String toString() => 'ApiException($code): $message';
}
