import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/menus_data_source.dart';
import '../../data/models/menu_detail.dart';
import '../../session/app_session.dart';
import 'menu_detail_state.dart';

class MenuDetailCubit extends Cubit<MenuDetailState> {
  final MenusDataSource _dataSource;
  final AppSession _session;
  final int menuId;

  MenuDetailCubit({
    required MenusDataSource dataSource,
    required AppSession session,
    required this.menuId,
  })  : _dataSource = dataSource,
        _session = session,
        super(const MenuDetailLoading());

  Future<void> load() async {
    emit(const MenuDetailLoading());
    try {
      final menu = await _dataSource.getMenuDetail(menuId, userId: _session.userId);
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
    // Grocery list generation is best-effort — if it fails, the menu is still
    // finalized. The GET endpoint will auto-generate on next visit.
    try {
      await _dataSource.generateGroceryList(menuId);
    } catch (_) {}
    await load();
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
        userId: _session.userId,
        value: value,
      );
    } catch (_) {
      emit(current);
    }
  }
}
