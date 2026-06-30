import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../cubits/groups/groups_cubit.dart';
import '../../cubits/groups/groups_state.dart';
import '../../data/groups_data_source.dart';
import '../../data/models/group.dart';
import '../../widgets/cards/group_card.dart';
import '../../widgets/states/empty_state.dart';
import '../../widgets/states/error_state.dart';
import '../../widgets/states/skeleton_list_item.dart';
import 'create_group_sheet.dart';

class GroupsScreen extends StatelessWidget {
  final GroupsDataSource dataSource;
  const GroupsScreen({super.key, required this.dataSource});

  void _openCreateSheet(BuildContext context) async {
    await showCreateGroupSheet(
      context,
      dataSource: dataSource,
    );
    if (context.mounted) {
      context.read<GroupsCubit>().loadGroups();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCreateSheet(context),
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<GroupsCubit, GroupsState>(
        builder: (context, state) {
          if (state is GroupsLoading) {
            return const _GroupsLoading();
          }
          if (state is GroupsError) {
            return ErrorState(
              message: state.message,
              onRetry: () => context.read<GroupsCubit>().loadGroups(),
            );
          }
          if (state is GroupsLoaded) {
            return _GroupsList(
              groups: state.groups,
              onCreateGroup: () => _openCreateSheet(context),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _GroupsList extends StatelessWidget {
  final List<Group> groups;
  final VoidCallback onCreateGroup;
  const _GroupsList({required this.groups, required this.onCreateGroup});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverAppBar.large(title: Text('Your Groups')),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          sliver: groups.isEmpty
              ? SliverFillRemaining(
                  child: EmptyState(
                    icon: LucideIcons.users,
                    title: 'No groups yet',
                    body: 'Create a group to start planning meals together.',
                    actionLabel: 'Create group',
                    onAction: onCreateGroup,
                  ),
                )
              : SliverList.separated(
                  itemCount: groups.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final g = groups[i];
                    return GroupCard(
                      name: g.name,
                      memberCount: 0,
                      threshold: g.threshold,
                      onTap: () => context.push('/groups/${g.groupId}'),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _GroupsLoading extends StatelessWidget {
  const _GroupsLoading();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverAppBar.large(title: Text('Your Groups')),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          sliver: SliverList.separated(
            itemCount: 5,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, _) => const SkeletonListItem(),
          ),
        ),
      ],
    );
  }
}
