import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/menus_data_source.dart';
import '../../data/models/active_menu_summary.dart';
import '../../session/app_session.dart';

// ---------- State ----------

abstract class PickMenuState extends Equatable {
  const PickMenuState();
  @override
  List<Object?> get props => [];
}

class PickMenuLoading extends PickMenuState {
  const PickMenuLoading();
}

class PickMenuLoaded extends PickMenuState {
  final List<ActiveMenuSummary> menus;
  final Set<int> addedMenuIds; // menus this recipe was added to in this session

  const PickMenuLoaded({required this.menus, this.addedMenuIds = const {}});

  PickMenuLoaded copyWith({Set<int>? addedMenuIds}) => PickMenuLoaded(
        menus: menus,
        addedMenuIds: addedMenuIds ?? this.addedMenuIds,
      );

  @override
  List<Object?> get props => [menus, addedMenuIds];
}

class PickMenuError extends PickMenuState {
  final String message;
  const PickMenuError(this.message);
  @override
  List<Object?> get props => [message];
}

// ---------- Cubit ----------

class PickMenuCubit extends Cubit<PickMenuState> {
  final MenusDataSource _dataSource;
  final AppSession _session;
  final int recipeId;

  PickMenuCubit({
    required MenusDataSource dataSource,
    required AppSession session,
    required this.recipeId,
  })  : _dataSource = dataSource,
        _session = session,
        super(const PickMenuLoading());

  Future<void> load() async {
    emit(const PickMenuLoading());
    try {
      final menus = await _dataSource.listActiveMenus(userId: _session.userId);
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
        userId: _session.userId,
      );
    } catch (_) {
      final ids = {...current.addedMenuIds}..remove(menuId);
      emit(current.copyWith(addedMenuIds: ids));
    }
  }
}
