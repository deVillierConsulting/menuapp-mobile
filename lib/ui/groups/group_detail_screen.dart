import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../cubits/group_detail/group_detail_cubit.dart';
import '../../cubits/group_detail/group_detail_state.dart';
import '../../data/models/menu.dart';
import '../../data/models/user.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_typography.dart';
import '../../widgets/cards/app_card.dart';
import '../../widgets/nav/app_page_header.dart';
import '../../widgets/states/empty_state.dart';
import '../../widgets/states/error_state.dart';

class GroupDetailScreen extends StatefulWidget {
  final int groupId;
  const GroupDetailScreen({super.key, required this.groupId});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<GroupDetailCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: BlocBuilder<GroupDetailCubit, GroupDetailState>(
        builder: (context, state) {
          if (state is GroupDetailLoading) return const _Loading();
          if (state is GroupDetailError) {
            return ErrorState(
              message: state.message,
              onRetry: () => context.read<GroupDetailCubit>().load(),
            );
          }
          if (state is GroupDetailLoaded) return _Loaded(state: state);
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _Loaded extends StatelessWidget {
  final GroupDetailLoaded state;
  const _Loaded({required this.state});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        AppPageHeader(title: state.group.name, showBack: true),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          sliver: SliverList.list(children: [
            _MemberRow(
              members: state.group.members,
              threshold: state.group.threshold,
              showThreshold: state.group.showThreshold,
            ),
            const SizedBox(height: 24),
            if (state.activeMenu != null) ...[
              Text('This week', style: AppTextStyles.label.copyWith(color: AppColors.ink3)),
              const SizedBox(height: 8),
              _MenuCard(menu: state.activeMenu!),
              const SizedBox(height: 24),
            ],
            if (state.pastMenus.isNotEmpty) ...[
              Text('Past menus', style: AppTextStyles.label.copyWith(color: AppColors.ink3)),
              const SizedBox(height: 8),
              ...state.pastMenus.map((m) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _MenuCard(menu: m),
                  )),
            ],
            if (state.activeMenu == null && state.pastMenus.isEmpty)
              EmptyState(
                icon: LucideIcons.calendarDays,
                title: 'No menus yet',
                body: 'Create a menu to start planning meals for this group.',
              ),
          ]),
        ),
      ],
    );
  }
}

class _MemberRow extends StatelessWidget {
  final List<User> members;
  final int threshold;
  final bool showThreshold;

  const _MemberRow({
    required this.members,
    required this.threshold,
    required this.showThreshold,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Overlapping avatar stack
        SizedBox(
          height: 40,
          width: (members.length * 28 + 12).toDouble().clamp(0, 160),
          child: Stack(
            children: [
              for (int i = 0; i < members.length; i++)
                Positioned(
                  left: i * 28.0,
                  child: _MemberAvatar(user: members[i]),
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '${members.length} member${members.length == 1 ? '' : 's'}',
          style: AppTextStyles.body.copyWith(color: AppColors.ink2),
        ),
        if (showThreshold) ...[
          const SizedBox(width: 6),
          Text(
            '· threshold $threshold',
            style: AppTextStyles.body.copyWith(color: AppColors.ink3),
          ),
        ],
      ],
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  final User user;
  const _MemberAvatar({required this.user});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.accent200,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.surface, width: 2),
      ),
      child: SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.accentDeep),
          ),
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final Menu menu;
  const _MenuCard({required this.menu});

  String get _dateRange {
    // "Jun 17 – Jun 19"
    final start = _formatDate(menu.startDate);
    final end = _formatDate(menu.endDate);
    return '$start – $end';
  }

  String _formatDate(String iso) {
    final d = DateTime.parse(iso);
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[d.month - 1]} ${d.day}';
  }

  Color get _statusColor => switch (menu.status) {
        MenuStatus.active => AppColors.ok,
        MenuStatus.final_ => AppColors.ink3,
        MenuStatus.draft  => AppColors.accent,
      };

  String get _statusLabel => switch (menu.status) {
        MenuStatus.active => 'Active',
        MenuStatus.final_ => 'Finalized',
        MenuStatus.draft  => 'Draft',
      };

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: () {
        // TODO: navigate to menu detail
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Photo collage placeholder — real photos slot in here (Task 14)
            _PhotoCollage(),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_dateRange, style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: _statusColor.withValues(alpha: 0.15),
                          borderRadius: AppRadii.fullAll,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          child: Text(
                            _statusLabel,
                            style: AppTextStyles.caption.copyWith(color: _statusColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.ink4, size: 20),
          ],
        ),
      ),
    );
  }
}

// 2×2 grid placeholder — swapped for real recipe photos in Task 14.
class _PhotoCollage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadii.smAll,
      child: SizedBox(
        width: 72,
        height: 72,
        child: GridView.count(
          crossAxisCount: 2,
          physics: const NeverScrollableScrollPhysics(),
          children: List.generate(
            4,
            (_) => DecoratedBox(
              decoration: BoxDecoration(color: AppColors.line2),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const CustomScrollView(
      slivers: [
        SliverAppBar.large(title: Text('')),
        SliverFillRemaining(
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
    );
  }
}
