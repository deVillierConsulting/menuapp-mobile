import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../cubits/home/home_cubit.dart';
import '../../cubits/home/home_state.dart';
import '../../data/models/active_menu_summary.dart';
import '../../data/models/menu_detail.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/voting/recipe_card_stack.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<HomeCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) => switch (state) {
          HomeLoading() => const _LoadingView(),
          HomeNoGroup()  => const _NoGroupView(),
          HomeNoMenu()   => const _NoMenuView(),
          HomeVoting()     => _VotingView(state: state),
          HomeWaiting()    => _WaitingView(state: state, finalizing: false),
          HomeFinalizing() => _WaitingView(
              state: HomeWaiting(menus: state.menus, selected: state.selected, detail: state.detail),
              finalizing: true,
            ),
          HomeFinalized()  => _FinalizedView(state: state),
          HomeError()    => _ErrorView(message: state.message),
          _ => const SizedBox.shrink(),
        },
      ),
    );
  }
}

// ── Loading ───────────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

// ── Error ─────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Something went wrong', style: AppTextStyles.bodyMedium),
          const SizedBox(height: 8),
          Text(message,
              style: AppTextStyles.caption.copyWith(color: AppColors.ink3),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => context.read<HomeCubit>().load(),
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

// ── No group ──────────────────────────────────────────────────────────────────

class _NoGroupView extends StatelessWidget {
  const _NoGroupView();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Align(
              alignment: Alignment.centerRight,
              child: _AccountButton(),
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🍽️', style: TextStyle(fontSize: 56)),
                    const SizedBox(height: 20),
                    Text('Start planning meals',
                        style: AppTextStyles.h1, textAlign: TextAlign.center),
                    const SizedBox(height: 10),
                    Text(
                      'Create a group to build your first weekly menu.',
                      style: AppTextStyles.body.copyWith(color: AppColors.ink2),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    FilledButton(
                      onPressed: () => context.push('/account'),
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accent),
                      child: const Text('Set up a group'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── No active menu ────────────────────────────────────────────────────────────

class _NoMenuView extends StatelessWidget {
  const _NoMenuView();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Align(
              alignment: Alignment.centerRight,
              child: _AccountButton(),
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('📅', style: TextStyle(fontSize: 56)),
                    const SizedBox(height: 20),
                    Text("No menu this week",
                        style: AppTextStyles.h1, textAlign: TextAlign.center),
                    const SizedBox(height: 10),
                    Text(
                      'Create a menu to start picking recipes for the week.',
                      style: AppTextStyles.body.copyWith(color: AppColors.ink2),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    FilledButton(
                      onPressed: () => context.push('/account'),
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accent),
                      child: const Text('Create a menu'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Voting ────────────────────────────────────────────────────────────────────

class _VotingView extends StatelessWidget {
  final HomeVoting state;
  const _VotingView({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<HomeCubit>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          children: [
            _TopBar(menus: state.menus, selected: state.selected),
            const SizedBox(height: 12),
            Expanded(
              child: RecipeCardStack(
                pending: state.pending,
                voted: state.voted,
                onVote: (menuRecipeId, value) =>
                    cubit.castVote(menuRecipeId, value),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Waiting on partner ────────────────────────────────────────────────────────

class _WaitingView extends StatelessWidget {
  final HomeWaiting state;
  final bool finalizing;
  const _WaitingView({required this.state, required this.finalizing});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<HomeCubit>();
    final approvedCount = state.detail.recipes
        .where((r) => r.voteSummary.userVote == VoteValue.approve)
        .length;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          children: [
            _TopBar(menus: state.menus, selected: state.selected),
            const Spacer(),
            const Text('🎉', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text("You're done voting!",
                style: AppTextStyles.h1, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'You approved $approvedCount recipe${approvedCount == 1 ? '' : 's'}. '
              'Finalize the menu when everyone is ready.',
              style: AppTextStyles.body.copyWith(color: AppColors.ink2),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: finalizing ? null : () => cubit.finalizeMenu(),
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.ok,
                  minimumSize: const Size.fromHeight(52)),
              child: finalizing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Finalize menu',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.push(
                  '/menus/${state.detail.menuId}'),
              child: const Text('Review recipes'),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

// ── Finalized ─────────────────────────────────────────────────────────────────

class _FinalizedView extends StatelessWidget {
  final HomeFinalized state;
  const _FinalizedView({required this.state});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TopBar(menus: state.menus, selected: state.selected),
            const SizedBox(height: 24),
            Text("This week's menu",
                style: AppTextStyles.h1),
            const SizedBox(height: 16),
            Expanded(
              child: _FinalizedRecipeList(detail: state.detail),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () =>
                  context.push('/menus/${state.detail.menuId}/grocery-list'),
              icon: const Icon(Icons.shopping_cart_outlined),
              label: const Text('Grocery list'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FinalizedRecipeList extends StatelessWidget {
  final MenuDetail detail;
  const _FinalizedRecipeList({required this.detail});

  @override
  Widget build(BuildContext context) {
    // In a finalized menu the server has already determined which recipes made
    // it — show all of them regardless of the current user's individual vote.
    final approved = detail.recipes;

    if (approved.isEmpty) {
      return Center(
        child: Text('No approved recipes',
            style: AppTextStyles.body.copyWith(color: AppColors.ink3)),
      );
    }

    return ListView.separated(
      itemCount: approved.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final mr = approved[i];
        return GestureDetector(
          onTap: () => context.push('/recipes/${mr.recipe.recipeId}'),
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(14)),
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: mr.recipe.photoKey != null
                        ? Image.network(mr.recipe.photoKey!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, err, stack) =>
                                const ColoredBox(color: AppColors.line))
                        : const ColoredBox(color: AppColors.line),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(mr.recipe.name,
                      style: AppTextStyles.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Shared: top bar with group pill selector ──────────────────────────────────

class _TopBar extends StatelessWidget {
  final List<ActiveMenuSummary> menus;
  final ActiveMenuSummary selected;

  const _TopBar({required this.menus, required this.selected});

  @override
  Widget build(BuildContext context) {
    if (menus.length <= 1) {
      return Row(
        children: [
          Text(selected.groupName,
              style: AppTextStyles.h1.copyWith(fontSize: 20)),
          const Spacer(),
          _WeekLabel(summary: selected),
          const SizedBox(width: 8),
          _AccountButton(),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: menus.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final m = menus[i];
                final isSelected = m.groupId == selected.groupId;
                return GestureDetector(
                  onTap: isSelected
                      ? null
                      : () => context.read<HomeCubit>().selectGroup(m),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.accent : AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected ? AppColors.accent : AppColors.line,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      m.groupName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isSelected ? Colors.white : AppColors.ink2,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
        _AccountButton(),
      ],
    );
  }
}

class _WeekLabel extends StatelessWidget {
  final ActiveMenuSummary summary;
  const _WeekLabel({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Text(
      summary.dateRange,
      style: AppTextStyles.caption.copyWith(color: AppColors.ink3),
    );
  }
}

// ── Account button + sign-out sheet ──────────────────────────────────────────

class _AccountButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/account'),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.line),
        ),
        child: const Icon(Icons.person_outline, size: 18, color: AppColors.ink2),
      ),
    );
  }
}

