class ShopItemSource {
  final String groupName;
  final int menuId;

  const ShopItemSource({required this.groupName, required this.menuId});

  factory ShopItemSource.fromJson(Map<String, dynamic> json) => ShopItemSource(
        groupName: json['group_name'] as String,
        menuId: json['menu_id'] as int,
      );
}

class ShopItem {
  final int ingredientId;
  final String ingredientName;
  final double? totalQuantity;
  final String? unit;
  final String category;
  final bool checked;
  final List<ShopItemSource> sources;

  const ShopItem({
    required this.ingredientId,
    required this.ingredientName,
    this.totalQuantity,
    this.unit,
    required this.category,
    required this.checked,
    required this.sources,
  });

  factory ShopItem.fromJson(Map<String, dynamic> json) => ShopItem(
        ingredientId: json['ingredient_id'] as int,
        ingredientName: json['ingredient_name'] as String,
        totalQuantity: (json['total_quantity'] as num?)?.toDouble(),
        unit: json['unit'] as String?,
        category: json['category'] as String? ?? 'Other',
        checked: json['checked'] as bool? ?? false,
        sources: (json['sources'] as List<dynamic>)
            .map((e) => ShopItemSource.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  // Stable key for check-off state: ingredient + unit combination.
  String get checkKey => '$ingredientId:${unit ?? ""}';

  ShopItem copyWith({bool? checked}) => ShopItem(
        ingredientId: ingredientId,
        ingredientName: ingredientName,
        totalQuantity: totalQuantity,
        unit: unit,
        category: category,
        checked: checked ?? this.checked,
        sources: sources,
      );
}
