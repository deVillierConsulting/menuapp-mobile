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

  Menu? get activeMenu =>
      menus.where((m) => m.isActive).firstOrNull;

  List<Menu> get pastMenus =>
      menus.where((m) => m.isFinal).toList();

  @override
  List<Object?> get props => [group, menus];
}

class GroupDetailError extends GroupDetailState {
  final String message;
  const GroupDetailError(this.message);
  @override
  List<Object?> get props => [message];
}
