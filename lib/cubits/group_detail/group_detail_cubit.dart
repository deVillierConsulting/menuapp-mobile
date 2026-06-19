import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/groups_data_source.dart';
import 'group_detail_state.dart';

class GroupDetailCubit extends Cubit<GroupDetailState> {
  final GroupsDataSource _dataSource;
  final int groupId;

  GroupDetailCubit({required GroupsDataSource dataSource, required this.groupId})
      : _dataSource = dataSource,
        super(const GroupDetailLoading());

  Future<void> load() async {
    emit(const GroupDetailLoading());
    try {
      // Fetch group and menus in parallel — neither depends on the other.
      final (group, menus) = await (
        _dataSource.getGroupDetail(groupId),
        _dataSource.getMenusForGroup(groupId),
      ).wait;
      emit(GroupDetailLoaded(group: group, menus: menus));
    } catch (e) {
      emit(GroupDetailError(e.toString()));
    }
  }
}
