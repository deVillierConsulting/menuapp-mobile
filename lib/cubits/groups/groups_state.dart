import 'package:equatable/equatable.dart';
import '../../data/models/group.dart';

abstract class GroupsState extends Equatable {
  const GroupsState();
  @override
  List<Object?> get props => [];
}

class GroupsLoading extends GroupsState {
  const GroupsLoading();
}

class GroupsLoaded extends GroupsState {
  final List<Group> groups;
  const GroupsLoaded(this.groups);
  @override
  List<Object?> get props => [groups];
}

class GroupsError extends GroupsState {
  final String message;
  const GroupsError(this.message);
  @override
  List<Object?> get props => [message];
}
