class InvitePreview {
  final String token;
  final int groupId;
  final String groupName;
  final String? inviterName;
  final int memberCount;
  final int mealsPerWeek;
  final DateTime expiresAt;

  const InvitePreview({
    required this.token,
    required this.groupId,
    required this.groupName,
    this.inviterName,
    required this.memberCount,
    required this.mealsPerWeek,
    required this.expiresAt,
  });

  factory InvitePreview.fromJson(Map<String, dynamic> json) => InvitePreview(
        token: json['token'] as String,
        groupId: json['group_id'] as int,
        groupName: json['group_name'] as String,
        inviterName: json['inviter_name'] as String?,
        memberCount: json['member_count'] as int,
        mealsPerWeek: json['meals_per_week'] as int,
        expiresAt: DateTime.parse(json['expires_at'] as String),
      );
}
