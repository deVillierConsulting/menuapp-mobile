import 'api_client.dart';
import 'models/recipe.dart';

class RecipesDataSource {
  final ApiClient _client;
  RecipesDataSource(this._client);

  Future<Recipe> getRecipe(int recipeId) async {
    final json = await _client.get('/recipes/$recipeId');
    return Recipe.fromJson(json as Map<String, dynamic>);
  }

  Future<List<Recipe>> listRecipes({int? cuisineId, int? tagId}) async {
    final params = [
      if (cuisineId != null) 'cuisine_id=$cuisineId',
      if (tagId != null) 'tag_id=$tagId',
    ];
    final query = params.isEmpty ? '' : '?${params.join('&')}';
    final json = await _client.get('/recipes/$query') as List<dynamic>;
    return json.map((e) => Recipe.fromJson(e as Map<String, dynamic>)).toList();
  }
}
