import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/group_repository.dart';
import 'groups_state.dart';

class GroupsCubit extends Cubit<GroupsState> {
  final GroupRepository _repository;

  GroupsCubit(this._repository) : super(const GroupsInitial());

  Future<void> loadGroups() async {
    emit(const GroupsLoading());
    try {
      final groups = await _repository.getGroups();
      emit(GroupsLoaded(groups));
    } catch (e) {
      emit(GroupsError(e.toString()));
    }
  }
}
