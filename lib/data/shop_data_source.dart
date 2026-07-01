import 'api_client.dart';
import 'models/shop_item.dart';

class ShopDataSource {
  final ApiClient _client;

  ShopDataSource(this._client);

  Future<List<ShopItem>> getShopList() async {
    final json = await _client.get('/shop/') as List<dynamic>;
    return json.map((e) => ShopItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> checkItem(int ingredientId, String? unit) async {
    await _client.post('/shop/check', {
      'ingredient_id': ingredientId,
      'unit': unit,
    });
  }

  Future<void> uncheckItem(int ingredientId, String? unit) async {
    await _client.delete('/shop/check', body: {
      'ingredient_id': ingredientId,
      'unit': unit,
    });
  }
}
