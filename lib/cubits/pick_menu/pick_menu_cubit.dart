import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/menus_data_source.dart';
import 'pick_menu_state.dart';

class PickMenuCubit extends Cubit<PickMenuState> {
  final MenusDataSource _dataSource;
  final int recipeId;

  PickMenuCubit({
    required MenusDataSource dataSource,
    required this.recipeId,
  })  : _dataSource = dataSource,
        super(const PickMenuLoading());

  Future<void> load() async {
    emit(const PickMenuLoading());
    try {
      final menus = await _dataSource.listActiveMenus();
      emit(PickMenuLoaded(menus: menus));
    } catch (e) {
      emit(PickMenuError(e.toString()));
    }
  }

  Future<void> addToMenu(int menuId) async {
    final current = state;
    if (current is! PickMenuLoaded) return;
    emit(current.copyWith(addedMenuIds: {...current.addedMenuIds, menuId}));
    try {
      await _dataSource.addRecipeToMenu(
        menuId: menuId,
        recipeId: recipeId,
      );
    } catch (_) {
      final ids = {...current.addedMenuIds}..remove(menuId);
      emit(current.copyWith(addedMenuIds: ids));
    }
  }
}
