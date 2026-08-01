import 'api_client.dart';
import 'models/invite_preview.dart';

class InviteDataSource {
  final ApiClient _client;

  InviteDataSource(this._client);

  /// Fetch group preview info for the join confirmation sheet.
  /// This endpoint is public — no auth token required.
  Future<InvitePreview> preview(String token) async {
    final json = await _client.get('/invites/$token');
    return InvitePreview.fromJson(json as Map<String, dynamic>);
  }

  /// Join the group. Requires the user to be authenticated.
  Future<void> join(String token) async {
    await _client.post('/invites/$token/join', {});
  }
}
