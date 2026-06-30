import 'api_client.dart';
import 'models/group.dart';
import 'models/group_detail.dart';
import 'models/menu.dart';

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
  }) async {
    final json = await _client.post('/groups/', {
      'name': name,
      'threshold': threshold,
    });
    return Group.fromJson(json as Map<String, dynamic>);
  }

  Future<GroupDetail> getGroupDetail(int groupId) async {
    final json = await _client.get('/groups/$groupId');
    return GroupDetail.fromJson(json as Map<String, dynamic>);
  }

  Future<void> removeMember(int groupId, int userId) async {
    await _client.delete('/groups/$groupId/members/$userId');
  }

  Future<List<Menu>> getMenusForGroup(int groupId) async {
    final json = await _client.get('/menus/group/$groupId') as List<dynamic>;
    return json.map((e) => Menu.fromJson(e as Map<String, dynamic>)).toList();
  }
}
