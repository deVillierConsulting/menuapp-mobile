import '../data/groups_data_source.dart';
import '../data/models/group.dart';

class GroupRepository {
  final GroupsDataSource _dataSource;

  GroupRepository(this._dataSource);

  Future<List<Group>> getGroups() => _dataSource.getGroups();

  Future<Group> createGroup({
    required String name,
    required int threshold,
    required int ownerId,
  }) => _dataSource.createGroup(
        name: name,
        threshold: threshold,
        ownerId: ownerId,
      );
}
