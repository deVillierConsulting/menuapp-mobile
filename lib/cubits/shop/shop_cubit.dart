import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/shop_data_source.dart';
import '../../data/models/shop_item.dart';
import 'shop_state.dart';

class ShopCubit extends Cubit<ShopState> {
  final ShopDataSource _dataSource;

  ShopCubit(this._dataSource) : super(const ShopLoading());

  Future<void> load() async {
    emit(const ShopLoading());
    try {
      final items = await _dataSource.getShopList();
      emit(ShopLoaded(items));
    } catch (e) {
      emit(ShopError(e.toString()));
    }
  }

  Future<void> toggle(ShopItem item) async {
    final current = state;
    if (current is! ShopLoaded) return;

    // Optimistically flip the checked flag.
    final nowChecked = !item.checked;
    final updated = current.items
        .map((i) => i.checkKey == item.checkKey ? i.copyWith(checked: nowChecked) : i)
        .toList();
    emit(ShopLoaded(updated));

    try {
      if (nowChecked) {
        await _dataSource.checkItem(item.ingredientId, item.unit);
      } else {
        await _dataSource.uncheckItem(item.ingredientId, item.unit);
      }
    } catch (_) {
      // Roll back on failure.
      emit(current);
    }
  }
}
