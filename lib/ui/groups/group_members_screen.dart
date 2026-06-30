import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/group_detail/group_detail_cubit.dart';
import '../../cubits/group_detail/group_detail_state.dart';
import '../../data/groups_data_source.dart';
import '../../data/models/user.dart';
import '../../session/app_session.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/nav/app_page_header.dart';

class GroupMembersScreen extends StatelessWidget {
  final int groupId;
  final GroupsDataSource dataSource;
  final AppSession session;

  const GroupMembersScreen({
    super.key,
    required this.groupId,
    required this.dataSource,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: BlocBuilder<GroupDetailCubit, GroupDetailState>(
        builder: (context, state) {
          if (state is! GroupDetailLoaded) return const SizedBox.shrink();
          final group = state.group;
          return CustomScrollView(
            slivers: [
              AppPageHeader(title: 'Members', showBack: true),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                sliver: SliverList.list(
                  children: [
                    ...group.members.map((member) => _MemberTile(
                          member: member,
                          isOwner: member.userId == group.ownerId,
                          canRemove: session.userId == group.ownerId &&
                              member.userId != group.ownerId,
                          onRemove: () => _removeMember(context, member),
                        )),
                    const SizedBox(height: 24),
                    _AddMemberStub(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _removeMember(BuildContext context, User member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Remove ${member.name}?'),
        content: Text('${member.name} will be removed from this group.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Remove', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await dataSource.removeMember(groupId, member.userId);
      if (context.mounted) {
        context.read<GroupDetailCubit>().load();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove member: $e')),
        );
      }
    }
  }
}

class _MemberTile extends StatelessWidget {
  final User member;
  final bool isOwner;
  final bool canRemove;
  final VoidCallback onRemove;

  const _MemberTile({
    required this.member,
    required this.isOwner,
    required this.canRemove,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.accent200,
            child: Text(
              member.name[0].toUpperCase(),
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.accentDeep),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.name, style: AppTextStyles.bodyMedium),
                Text(member.email,
                    style: AppTextStyles.caption.copyWith(color: AppColors.ink3)),
              ],
            ),
          ),
          if (isOwner)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.accent50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accent200),
              ),
              child: Text('Owner',
                  style: AppTextStyles.caption.copyWith(color: AppColors.accentDeep)),
            )
          else if (canRemove)
            IconButton(
              onPressed: onRemove,
              icon: Icon(Icons.remove_circle_outline_rounded,
                  color: AppColors.danger, size: 22),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}

class _AddMemberStub extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.person_add_outlined, color: AppColors.ink3, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Invite someone', style: AppTextStyles.bodyMedium),
                  Text('Coming once real auth is in place',
                      style: AppTextStyles.caption.copyWith(color: AppColors.ink3)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
