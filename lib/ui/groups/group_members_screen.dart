import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart' show Share;
import '../../cubits/group_detail/group_detail_cubit.dart';
import '../../cubits/group_detail/group_detail_state.dart';
import '../../data/groups_data_source.dart';
import '../../data/models/group_invite.dart';
import '../../data/models/user.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/nav/app_page_header.dart';

class GroupMembersScreen extends StatelessWidget {
  final int groupId;
  final GroupsDataSource dataSource;
  final int currentUserId;

  const GroupMembersScreen({
    super.key,
    required this.groupId,
    required this.dataSource,
    required this.currentUserId,
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
                          canRemove: currentUserId == group.ownerId &&
                              member.userId != group.ownerId,
                          onRemove: () => _removeMember(context, member),
                        )),
                    const SizedBox(height: 24),
                    _InviteSection(groupId: groupId, dataSource: dataSource),
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

// ── Invite section ────────────────────────────────────────────────────────────

class _InviteSection extends StatefulWidget {
  final int groupId;
  final GroupsDataSource dataSource;

  const _InviteSection({required this.groupId, required this.dataSource});

  @override
  State<_InviteSection> createState() => _InviteSectionState();
}

class _InviteSectionState extends State<_InviteSection> {
  GroupInvite? _invite;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final invite = await widget.dataSource.getOrCreateInvite(widget.groupId);
      if (mounted) setState(() { _invite = invite; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _refresh() async {
    setState(() { _loading = true; _error = null; });
    try {
      final invite = await widget.dataSource.refreshInvite(widget.groupId);
      if (mounted) setState(() { _invite = invite; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  String get _shareUrl {
    // Once Universal Links are live this becomes https://menuapp.io/join/{token}.
    // For now we use the custom scheme so it can still be opened by the app
    // when installed, and shared as text otherwise.
    return 'menuapp://join/${_invite!.token}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Invite', style: AppTextStyles.label.copyWith(color: AppColors.ink3)),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _loading
                ? const SizedBox(
                    height: 40,
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
                : _error != null
                    ? Row(children: [
                        const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('Could not load invite link',
                              style: AppTextStyles.caption.copyWith(color: AppColors.ink3))),
                        TextButton(onPressed: _fetch, child: const Text('Retry')),
                      ])
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Share this link to invite someone to the group.',
                              style: AppTextStyles.caption.copyWith(color: AppColors.ink2)),
                          const SizedBox(height: 12),
                          // Token pill — tap to copy
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: _shareUrl));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Invite link copied')));
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.bg,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.line),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _shareUrl,
                                      style: AppTextStyles.caption
                                          .copyWith(color: AppColors.ink2),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.copy_rounded,
                                      size: 16, color: AppColors.ink3),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: () => Share.share(
                                    'Join my group on MenuApp!\n$_shareUrl',
                                  ),
                                  icon: const Icon(Icons.share_rounded, size: 18),
                                  label: const Text('Share invite'),
                                  style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.accent),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Refresh generates a new token, invalidating the old one
                              IconButton(
                                tooltip: 'Get a new link',
                                onPressed: _refresh,
                                icon: const Icon(Icons.refresh_rounded,
                                    color: AppColors.ink3),
                              ),
                            ],
                          ),
                          if (_invite!.expiresAt.isAfter(DateTime.now())) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Expires ${_formatExpiry(_invite!.expiresAt)}',
                              style:
                                  AppTextStyles.caption.copyWith(color: AppColors.ink3),
                            ),
                          ],
                        ],
                      ),
          ),
        ),
      ],
    );
  }

  String _formatExpiry(DateTime dt) {
    final diff = dt.difference(DateTime.now());
    if (diff.inDays >= 1) return 'in ${diff.inDays}d';
    if (diff.inHours >= 1) return 'in ${diff.inHours}h';
    return 'soon';
  }
}
