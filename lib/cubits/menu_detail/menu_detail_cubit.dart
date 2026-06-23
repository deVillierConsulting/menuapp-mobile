import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/menus_data_source.dart';
import '../../data/models/menu_detail.dart';
import 'menu_detail_state.dart';

class MenuDetailCubit extends Cubit<MenuDetailState> {
  final MenusDataSource _dataSource;
  final int menuId;

  MenuDetailCubit({required MenusDataSource dataSource, required this.menuId})
      : _dataSource = dataSource,
        super(const MenuDetailLoading());

  Future<void> load() async {
    emit(const MenuDetailLoading());
    try {
      // user_id 1 = Andrew (hardcoded until auth lands — Task #20)
      final menu = await _dataSource.getMenuDetail(menuId, userId: 1);
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
      await _dataSource.generateGroceryList(menuId);
      await load(); // reload so status flips to final in the UI
    } catch (e) {
      emit(MenuDetailError(e.toString()));
    }
  }

  Future<void> castVote(int menuRecipeId, VoteValue value) async {
    final current = state;
    if (current is! MenuDetailLoaded) return;

    // Optimistic update — reflect the vote immediately so the UI feels instant.
    final optimistic = current.menu.copyWithUpdatedVote(menuRecipeId, value);
    emit(MenuDetailLoaded(optimistic));

    try {
      await _dataSource.castVote(
        menuId: menuId,
        menuRecipeId: menuRecipeId,
        userId: 1,
        value: value,
      );
      // Server confirmed — optimistic state already matches, nothing to do.
    } catch (_) {
      // Revert to the pre-vote state on failure.
      emit(current);
    }
  }
}
