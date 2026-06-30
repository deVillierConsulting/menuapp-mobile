import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/menus_data_source.dart';
import 'create_menu_state.dart';

class CreateMenuCubit extends Cubit<CreateMenuState> {
  final MenusDataSource _dataSource;
  final int groupId;

  CreateMenuCubit({required MenusDataSource dataSource, required this.groupId})
      : _dataSource = dataSource,
        super(_defaultIdle());

  static CreateMenuIdle _defaultIdle() {
    final today = DateTime.now();
    // Default to the coming Monday→Sunday week.
    final daysUntilMonday = (DateTime.monday - today.weekday + 7) % 7;
    final start = today.add(Duration(days: daysUntilMonday == 0 ? 7 : daysUntilMonday));
    final end = start.add(const Duration(days: 6));
    return CreateMenuIdle(
      startDate: start,
      endDate: end,
      plannedMealCount: 5,
    );
  }

  void setDateRange(DateTime start, DateTime end) {
    final current = state;
    if (current is! CreateMenuIdle) return;
    emit(current.copyWith(startDate: start, endDate: end));
  }

  void setName(String value) {
    final current = state;
    if (current is! CreateMenuIdle) return;
    final trimmed = value.trim();
    emit(trimmed.isEmpty
        ? current.copyWith(clearName: true)
        : current.copyWith(name: trimmed));
  }

  void setMealCount(int count) {
    final current = state;
    if (current is! CreateMenuIdle) return;
    if (count < 1) return;
    emit(current.copyWith(plannedMealCount: count));
  }

  Future<void> submit() async {
    final current = state;
    if (current is! CreateMenuIdle) return;
    emit(const CreateMenuSubmitting());
    try {
      final menu = await _dataSource.createMenu(
        groupId: groupId,
        name: current.name,
        startDate: current.startDate,
        endDate: current.endDate,
        plannedMealCount: current.plannedMealCount,
      );
      emit(CreateMenuSuccess(menu.menuId));
    } catch (e) {
      emit(CreateMenuError(e.toString()));
    }
  }
}
