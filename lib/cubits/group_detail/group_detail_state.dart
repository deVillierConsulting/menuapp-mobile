import 'package:equatable/equatable.dart';
import '../../data/models/group_detail.dart';
import '../../data/models/menu.dart';

abstract class GroupDetailState extends Equatable {
  const GroupDetailState();
  @override
  List<Object?> get props => [];
}

class GroupDetailLoading extends GroupDetailState {
  const GroupDetailLoading();
}

class GroupDetailLoaded extends GroupDetailState {
  final GroupDetail group;
  final List<Menu> menus;

  const GroupDetailLoaded({required this.group, required this.menus});

  // The menu being voted on and built out right now.
  Menu? get planningMenu =>
      menus.where((m) => m.isActive).firstOrNull;

  // The finalized menu the group is cooking from this week.
  Menu? get currentMenu =>
      menus.where((m) => m.isFinal).firstOrNull;

  @override
  List<Object?> get props => [group, menus];
}

class GroupDetailError extends GroupDetailState {
  final String message;
  const GroupDetailError(this.message);
  @override
  List<Object?> get props => [message];
}
