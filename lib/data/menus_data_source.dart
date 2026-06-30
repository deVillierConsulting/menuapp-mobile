import 'api_client.dart';
import 'models/active_menu_summary.dart';
import 'models/grocery_list.dart';
import 'models/menu.dart';
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

  Future<Menu> createMenu({
    required int groupId,
    String? name,
    required DateTime startDate,
    required DateTime endDate,
    required int plannedMealCount,
  }) async {
    String fmt(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final body = <String, dynamic>{
      'group_id': groupId,
      'start_date': fmt(startDate),
      'end_date': fmt(endDate),
      'planned_meal_count': plannedMealCount,
    };
    if (name != null) body['name'] = name;
    final json = await _client.post('/menus/', body);
    return Menu.fromJson(json as Map<String, dynamic>);
  }

  Future<void> finalizeMenu(int menuId) async {
    await _client.patch('/menus/$menuId/status', {'status': 'final'});
  }

  Future<GroceryList> generateGroceryList(int menuId) async {
    final json = await _client.post('/menus/$menuId/grocery-list', {});
    return GroceryList.fromJson(json as Map<String, dynamic>);
  }

  Future<GroceryList> getGroceryList(int menuId) async {
    final json = await _client.get('/menus/$menuId/grocery-list');
    return GroceryList.fromJson(json as Map<String, dynamic>);
  }

  Future<List<ActiveMenuSummary>> listActiveMenus({required int userId}) async {
    final json = await _client.get('/menus/active?user_id=$userId') as List<dynamic>;
    return json
        .map((e) => ActiveMenuSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<MenuRecipe> addRecipeToMenu({
    required int menuId,
    required int recipeId,
    required int userId,
  }) async {
    final json = await _client.post('/menus/$menuId/recipes', {
      'recipe_id': recipeId,
      'added_by_user_id': userId,
    });
    return MenuRecipe.fromJson(json as Map<String, dynamic>);
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
