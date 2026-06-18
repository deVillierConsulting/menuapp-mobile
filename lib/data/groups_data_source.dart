import 'api_client.dart';
import 'models/group.dart';

class GroupsDataSource {
  final ApiClient _client;

  GroupsDataSource(this._client);

  Future<List<Group>> getGroups() async {
    final json = await _client.get('/groups/') as List<dynamic>;
    return json.map((e) => Group.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Group> createGroup({
    required String name,
    required int threshold,
    required int ownerId,
  }) async {
    final json = await _client.post('/groups/', {
      'name': name,
      'threshold': threshold,
      'owner_id': ownerId,
    });
    return Group.fromJson(json as Map<String, dynamic>);
  }
}
