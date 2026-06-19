import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../cubits/groups/groups_cubit.dart';
import '../../cubits/groups/groups_state.dart';
import '../../data/models/group.dart';
import '../../widgets/cards/group_card.dart';
import '../../widgets/states/empty_state.dart';
import '../../widgets/states/error_state.dart';
import '../../widgets/states/skeleton_list_item.dart';

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GroupsCubit, GroupsState>(
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
          return _GroupsList(groups: state.groups);
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _GroupsList extends StatelessWidget {
  final List<Group> groups;
  const _GroupsList({required this.groups});

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
                    onAction: () {
                      // TODO: navigate to create group
                    },
                  ),
                )
              : SliverList.separated(
                  itemCount: groups.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
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
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, __) => const SkeletonListItem(),
          ),
        ),
      ],
    );
  }
}
