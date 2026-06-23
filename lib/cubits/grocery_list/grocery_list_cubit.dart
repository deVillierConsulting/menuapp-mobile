import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/menus_data_source.dart';
import '../../data/models/grocery_list.dart';

abstract class GroceryListState extends Equatable {
  const GroceryListState();
  @override
  List<Object?> get props => [];
}

class GroceryListLoading extends GroceryListState {
  const GroceryListLoading();
}

class GroceryListLoaded extends GroceryListState {
  final GroceryList groceryList;
  final Set<int> checkedIds; // items ticked off while shopping

  const GroceryListLoaded({required this.groceryList, this.checkedIds = const {}});

  GroceryListLoaded copyWith({Set<int>? checkedIds}) =>
      GroceryListLoaded(groceryList: groceryList, checkedIds: checkedIds ?? this.checkedIds);

  @override
  List<Object?> get props => [groceryList, checkedIds];
}

class GroceryListError extends GroceryListState {
  final String message;
  const GroceryListError(this.message);
  @override
  List<Object?> get props => [message];
}

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
