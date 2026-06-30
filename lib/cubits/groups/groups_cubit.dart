import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/groups_data_source.dart';
import 'groups_state.dart';

class GroupsCubit extends Cubit<GroupsState> {
  final GroupsDataSource _dataSource;

  GroupsCubit(this._dataSource) : super(const GroupsLoading());

  Future<void> loadGroups() async {
    emit(const GroupsLoading());
    try {
      final groups = await _dataSource.getGroups();
      emit(GroupsLoaded(groups));
    } catch (e) {
      emit(GroupsError(e.toString()));
    }
  }
}
