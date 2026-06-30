import 'api_client.dart';

class AuthResult {
  final String accessToken;
  final int userId;
  final String userName;

  const AuthResult({
    required this.accessToken,
    required this.userId,
    required this.userName,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
        accessToken: json['access_token'] as String,
        userId: json['user_id'] as int,
        userName: json['user_name'] as String,
      );
}

class AuthDataSource {
  final ApiClient _client;
  AuthDataSource(this._client);

  Future<AuthResult> devLogin(String email) async {
    final json = await _client.post('/auth/dev-login', {'email': email});
    return AuthResult.fromJson(json as Map<String, dynamic>);
  }
}
