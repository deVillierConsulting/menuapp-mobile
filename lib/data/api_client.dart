import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  final String baseUrl;
  final http.Client _client;
  String? _token;

  ApiClient({required this.baseUrl}) : _client = http.Client();

  void setToken(String token) => _token = token;
  void clearToken() => _token = null;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<dynamic> get(String path) => _request('GET', path);
  Future<dynamic> post(String path, Map<String, dynamic> body) =>
      _request('POST', path, body: body);
  Future<dynamic> patch(String path, Map<String, dynamic> body) =>
      _request('PATCH', path, body: body);
  Future<void> delete(String path, {Map<String, dynamic>? body}) =>
      _request('DELETE', path, body: body);

  Future<dynamic> _request(String method, String path,
      {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    final http.Response response;

    switch (method) {
      case 'GET':
        response = await _client.get(uri, headers: _headers);
      case 'POST':
        response = await _client.post(uri,
            headers: _headers, body: jsonEncode(body));
      case 'PATCH':
        response = await _client.patch(uri,
            headers: _headers, body: jsonEncode(body));
      case 'DELETE':
        // http.Client.delete doesn't support a body; use a raw Request instead.
        final req = http.Request('DELETE', uri)
          ..headers.addAll(_headers);
        if (body != null) req.body = jsonEncode(body);
        final streamed = await _client.send(req);
        response = await http.Response.fromStream(streamed);
      default:
        throw ApiException(0, 'Unknown method: $method');
    }

    if (response.statusCode == 204) return null;

    if (response.statusCode >= 400) {
      final detail = _parseDetail(response.body);
      throw ApiException(response.statusCode, detail);
    }

    return jsonDecode(response.body);
  }

  String _parseDetail(String body) {
    try {
      final json = jsonDecode(body);
      return json['detail'] ?? 'Unknown error';
    } catch (_) {
      return 'Unknown error';
    }
  }
}
