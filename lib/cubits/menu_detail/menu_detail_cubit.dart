import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/menus_data_source.dart';
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
}
