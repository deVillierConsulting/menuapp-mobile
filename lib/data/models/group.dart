import 'package:equatable/equatable.dart';

class Group extends Equatable {
  final int groupId;
  final String name;
  final int threshold;
  final int ownerId;
  final String createdAt;

  const Group({
    required this.groupId,
    required this.name,
    required this.threshold,
    required this.ownerId,
    required this.createdAt,
  });

  factory Group.fromJson(Map<String, dynamic> json) => Group(
        groupId: json['group_id'] as int,
        name: json['name'] as String,
        threshold: json['threshold'] as int,
        ownerId: json['owner_id'] as int,
        createdAt: json['created_at'] as String,
      );

  @override
  List<Object?> get props => [groupId, name, threshold, ownerId, createdAt];
}
