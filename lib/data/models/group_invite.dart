class GroupInvite {
  final int groupInviteId;
  final int groupId;
  final String token;
  final DateTime expiresAt;

  const GroupInvite({
    required this.groupInviteId,
    required this.groupId,
    required this.token,
    required this.expiresAt,
  });

  factory GroupInvite.fromJson(Map<String, dynamic> json) => GroupInvite(
        groupInviteId: json['group_invite_id'] as int,
        groupId: json['group_id'] as int,
        token: json['token'] as String,
        expiresAt: DateTime.parse(json['expires_at'] as String),
      );
}
