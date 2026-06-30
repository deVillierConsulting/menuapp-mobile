import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/menus_data_source.dart';
import 'grocery_list_state.dart';

class GroceryListCubit extends Cubit<GroceryListState> {
  final MenusDataSource _dataSource;
  final int menuId;

  GroceryListCubit({required MenusDataSource dataSource, required this.menuId})
      : _dataSource = dataSource,
        super(const GroceryListLoading());

  Future<void> load() async {
    emit(const GroceryListLoading());
    try {
      final list = await _dataSource.getGroceryList(menuId);
      emit(GroceryListLoaded(groceryList: list));
    } catch (e) {
      emit(GroceryListError(e.toString()));
    }
  }

  void toggleItem(int itemId) {
    final current = state;
    if (current is! GroceryListLoaded) return;
    final updated = Set<int>.from(current.checkedIds);
    if (updated.contains(itemId)) {
      updated.remove(itemId);
    } else {
      updated.add(itemId);
    }
    emit(current.copyWith(checkedIds: updated));
  }
}
