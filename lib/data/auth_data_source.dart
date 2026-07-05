import 'api_client.dart';

class MeResult {
  final int userId;
  final String userName;
  final String email;

  const MeResult({
    required this.userId,
    required this.userName,
    required this.email,
  });

  factory MeResult.fromJson(Map<String, dynamic> json) => MeResult(
        userId: json['user_id'] as int,
        userName: json['user_name'] as String,
        email: json['email'] as String,
      );
}

class AuthDataSource {
  final ApiClient _client;
  AuthDataSource(this._client);

  /// Validate the current token and return the user's identity.
  /// Throws ApiException(404) if the user has no profile yet.
  Future<MeResult> me() async {
    final json = await _client.get('/auth/me');
    return MeResult.fromJson(json as Map<String, dynamic>);
  }

  /// Create a user profile for a first-time Supabase sign-in.
  Future<MeResult> register(String name) async {
    final json = await _client.post('/auth/register', {'name': name});
    return MeResult.fromJson(json as Map<String, dynamic>);
  }
}
