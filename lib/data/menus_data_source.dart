import 'api_client.dart';
import 'models/menu_detail.dart';

class MenusDataSource {
  final ApiClient _client;
  MenusDataSource(this._client);

  // user_id is passed so the backend can populate vote_summary.user_vote.
  // Until auth lands, caller passes the hardcoded dev user id.
  Future<MenuDetail> getMenuDetail(int menuId, {int? userId}) async {
    final query = userId != null ? '?user_id=$userId' : '';
    final json = await _client.get('/menus/$menuId$query');
    return MenuDetail.fromJson(json as Map<String, dynamic>);
  }

  Future<void> castVote({
    required int menuId,
    required int menuRecipeId,
    required int userId,
    required VoteValue value,
  }) async {
    await _client.post(
      '/menus/$menuId/recipes/$menuRecipeId/vote',
      {'user_id': userId, 'vote_value': value.name},
    );
  }
}
