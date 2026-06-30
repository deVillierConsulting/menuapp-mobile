import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/groups_data_source.dart';
import '../../session/app_session.dart';
import 'create_group_state.dart';

class CreateGroupCubit extends Cubit<CreateGroupState> {
  final GroupsDataSource _dataSource;
  final AppSession _session;

  CreateGroupCubit({
    required GroupsDataSource dataSource,
    required AppSession session,
  })  : _dataSource = dataSource,
        _session = session,
        super(const CreateGroupIdle());

  void setName(String value) {
    final current = state;
    if (current is! CreateGroupIdle) return;
    emit(current.copyWith(name: value));
  }

  Future<void> submit() async {
    final current = state;
    if (current is! CreateGroupIdle || !current.canSubmit) return;
    emit(const CreateGroupSubmitting());
    try {
      final group = await _dataSource.createGroup(
        name: current.name.trim(),
        threshold: 1,
        ownerId: _session.userId,
      );
      emit(CreateGroupSuccess(group.groupId));
    } catch (e) {
      emit(CreateGroupError(e.toString()));
      emit(CreateGroupIdle(name: current.name));
    }
  }
}
