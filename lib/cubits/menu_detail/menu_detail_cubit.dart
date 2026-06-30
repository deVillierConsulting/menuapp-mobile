import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/menus_data_source.dart';
import '../../data/models/menu_detail.dart';
import 'menu_detail_state.dart';

class MenuDetailCubit extends Cubit<MenuDetailState> {
  final MenusDataSource _dataSource;
  final int menuId;

  MenuDetailCubit({
    required MenusDataSource dataSource,
    required this.menuId,
  })  : _dataSource = dataSource,
        super(const MenuDetailLoading());

  Future<void> load() async {
    emit(const MenuDetailLoading());
    try {
      final menu = await _dataSource.getMenuDetail(menuId);
      emit(MenuDetailLoaded(menu));
    } catch (e) {
      emit(MenuDetailError(e.toString()));
    }
  }

  Future<void> finalizeMenu() async {
    final current = state;
    if (current is! MenuDetailLoaded) return;
    try {
      await _dataSource.finalizeMenu(menuId);
    } catch (e) {
      emit(MenuDetailError(e.toString()));
      return;
    }
    try {
      await _dataSource.generateGroceryList(menuId);
    } catch (_) {}
    await load();
  }

  Future<void> castVote(int menuRecipeId, VoteValue value) async {
    final current = state;
    if (current is! MenuDetailLoaded) return;

    final optimistic = current.menu.copyWithUpdatedVote(menuRecipeId, value);
    emit(MenuDetailLoaded(optimistic));

    try {
      await _dataSource.castVote(
        menuId: menuId,
        menuRecipeId: menuRecipeId,
        value: value,
      );
    } catch (_) {
      emit(current);
    }
  }
}
