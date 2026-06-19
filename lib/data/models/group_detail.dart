import 'package:equatable/equatable.dart';
import 'user.dart';

class GroupDetail extends Equatable {
  final int groupId;
  final String name;
  final int threshold;
  final int ownerId;
  final List<User> members;

  const GroupDetail({
    required this.groupId,
    required this.name,
    required this.threshold,
    required this.ownerId,
    required this.members,
  });

  factory GroupDetail.fromJson(Map<String, dynamic> json) => GroupDetail(
        groupId: json['group_id'] as int,
        name: json['name'] as String,
        threshold: json['threshold'] as int,
        ownerId: json['owner_id'] as int,
        members: (json['members'] as List<dynamic>)
            .map((e) => User.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  // Show threshold only for groups of 3+ where the owner has set it above
  // simple majority. For couples, "both agree" is the natural expectation
  // and the number adds no value.
  bool get showThreshold =>
      members.length > 2 && threshold > (members.length / 2).ceil();

  @override
  List<Object?> get props => [groupId, name, threshold, ownerId, members];
}
