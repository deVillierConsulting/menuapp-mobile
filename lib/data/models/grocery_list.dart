import 'package:equatable/equatable.dart';

class GroceryListItem extends Equatable {
  final int groceryListItemId;
  final int ingredientId;
  final String ingredientName;
  final double? totalQuantity;
  final String? unit;

  const GroceryListItem({
    required this.groceryListItemId,
    required this.ingredientId,
    required this.ingredientName,
    this.totalQuantity,
    this.unit,
  });

  factory GroceryListItem.fromJson(Map<String, dynamic> json) => GroceryListItem(
        groceryListItemId: json['grocery_list_item_id'] as int,
        ingredientId: json['ingredient_id'] as int,
        ingredientName: json['ingredient_name'] as String,
        totalQuantity: (json['total_quantity'] as num?)?.toDouble(),
        unit: json['unit'] as String?,
      );

  String get displayQuantity {
    if (totalQuantity == null) return '';
    final qty = totalQuantity! % 1 == 0
        ? totalQuantity!.toInt().toString()
        : totalQuantity!.toStringAsFixed(1);
    return unit != null ? '$qty $unit' : qty;
  }

  @override
  List<Object?> get props =>
      [groceryListItemId, ingredientId, ingredientName, totalQuantity, unit];
}

class GroceryList extends Equatable {
  final int groceryListId;
  final int menuId;
  final List<GroceryListItem> items;

  const GroceryList({
    required this.groceryListId,
    required this.menuId,
    required this.items,
  });

  factory GroceryList.fromJson(Map<String, dynamic> json) => GroceryList(
        groceryListId: json['grocery_list_id'] as int,
        menuId: json['menu_id'] as int,
        items: (json['items'] as List<dynamic>)
            .map((e) => GroceryListItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  List<Object?> get props => [groceryListId, menuId, items];
}
