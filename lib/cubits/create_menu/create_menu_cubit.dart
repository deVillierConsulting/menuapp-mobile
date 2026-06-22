import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/menus_data_source.dart';

// ---------- State ----------

abstract class CreateMenuState extends Equatable {
  const CreateMenuState();
  @override
  List<Object?> get props => [];
}

class CreateMenuIdle extends CreateMenuState {
  final String? name; // null = use server-generated default
  final DateTime startDate;
  final DateTime endDate;
  final int plannedMealCount;

  const CreateMenuIdle({
    this.name,
    required this.startDate,
    required this.endDate,
    required this.plannedMealCount,
  });

  int get dayCount => endDate.difference(startDate).inDays + 1;

  // Mirror the server's default name so the placeholder stays in sync with the date picker.
  String get defaultName {
    const ordinals = ['First', 'Second', 'Third', 'Fourth', 'Fifth'];
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final week = (startDate.day - 1) ~/ 7;
    return '${ordinals[week]} week of ${months[startDate.month - 1]}';
  }

  CreateMenuIdle copyWith({
    String? name,
    bool clearName = false,
    DateTime? startDate,
    DateTime? endDate,
    int? plannedMealCount,
  }) =>
      CreateMenuIdle(
        name: clearName ? null : (name ?? this.name),
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        plannedMealCount: plannedMealCount ?? this.plannedMealCount,
      );

  @override
  List<Object?> get props => [name, startDate, endDate, plannedMealCount];
}

class CreateMenuSubmitting extends CreateMenuState {
  const CreateMenuSubmitting();
}

class CreateMenuSuccess extends CreateMenuState {
  final int menuId;
  const CreateMenuSuccess(this.menuId);
  @override
  List<Object?> get props => [menuId];
}

class CreateMenuError extends CreateMenuState {
  final String message;
  const CreateMenuError(this.message);
  @override
  List<Object?> get props => [message];
}

// ---------- Cubit ----------

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
      plannedMealCount: 5, // sensible default: 5 dinners in a 7-day week
    );
  }

  void setDateRange(DateTime start, DateTime end) {
    final current = state;
    if (current is! CreateMenuIdle) return;
    emit(current.copyWith(
      startDate: start,
      endDate: end,
    ));
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
      final json = await _dataSource.createMenu(
        groupId: groupId,
        name: current.name, // null → server generates the default
        startDate: current.startDate,
        endDate: current.endDate,
        plannedMealCount: current.plannedMealCount,
      );
      emit(CreateMenuSuccess(json['menu_id'] as int));
    } catch (e) {
      emit(CreateMenuError(e.toString()));
    }
  }
}
