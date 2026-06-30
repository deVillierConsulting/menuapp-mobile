import 'package:equatable/equatable.dart';
import '../../data/models/active_menu_summary.dart';

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
