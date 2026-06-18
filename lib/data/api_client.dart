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

  ApiClient({required this.baseUrl}) : _client = http.Client();

  Map<String, String> get _headers => {'Content-Type': 'application/json'};

  Future<dynamic> get(String path) => _request('GET', path);
  Future<dynamic> post(String path, Map<String, dynamic> body) =>
      _request('POST', path, body: body);
  Future<dynamic> patch(String path, Map<String, dynamic> body) =>
      _request('PATCH', path, body: body);
  Future<void> delete(String path) => _request('DELETE', path);

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
        response = await _client.delete(uri, headers: _headers);
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
