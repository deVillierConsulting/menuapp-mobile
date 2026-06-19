import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../cubits/menu_detail/menu_detail_cubit.dart';
import '../../cubits/menu_detail/menu_detail_state.dart';
import '../../data/models/menu.dart';
import '../../data/models/menu_detail.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_typography.dart';
import '../../widgets/cards/app_card.dart';
import '../../widgets/nav/app_page_header.dart';
import '../../widgets/states/empty_state.dart';
import '../../widgets/states/error_state.dart';

class MenuDetailScreen extends StatefulWidget {
  final int menuId;
  const MenuDetailScreen({super.key, required this.menuId});

  @override
  State<MenuDetailScreen> createState() => _MenuDetailScreenState();
}

class _MenuDetailScreenState extends State<MenuDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<MenuDetailCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: BlocBuilder<MenuDetailCubit, MenuDetailState>(
        builder: (context, state) {
          if (state is MenuDetailLoading) {
            return const _Loading();
          }
          if (state is MenuDetailError) {
            return ErrorState(
              message: state.message,
              onRetry: () => context.read<MenuDetailCubit>().load(),
            );
          }
          if (state is MenuDetailLoaded) {
            return _Loaded(menu: state.menu);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _Loaded extends StatelessWidget {
  final MenuDetail menu;
  const _Loaded({required this.menu});

  String get _title {
    final start = _fmt(menu.startDate);
    final end = _fmt(menu.endDate);
    return '$start – $end';
  }

  String _fmt(String iso) {
    final d = DateTime.parse(iso);
    const m = ['Jan','Feb','Mar','Apr','May','Jun',
                'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[d.month - 1]} ${d.day}';
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        AppPageHeader(title: _title, showBack: true),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          sliver: SliverList.list(children: [
            _StatusRow(menu: menu),
            const SizedBox(height: 20),
            _CompletenessBar(menu: menu),
            const SizedBox(height: 24),
            if (menu.recipes.isEmpty)
              EmptyState(
                icon: LucideIcons.utensils,
                title: 'No recipes yet',
                body: 'Add recipes from the library to start planning this week.',
              )
            else ...[
              Text('Recipes', style: AppTextStyles.label.copyWith(color: AppColors.ink3)),
              const SizedBox(height: 8),
              ...menu.recipes.map((mr) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _RecipeCard(menuRecipe: mr),
                  )),
            ],
          ]),
        ),
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  final MenuDetail menu;
  const _StatusRow({required this.menu});

  Color get _color => switch (menu.status) {
        MenuStatus.active => AppColors.ok,
        MenuStatus.final_ => AppColors.ink3,
        MenuStatus.draft  => AppColors.accent,
      };

  String get _label => switch (menu.status) {
        MenuStatus.active => 'Active',
        MenuStatus.final_ => 'Finalized',
        MenuStatus.draft  => 'Draft',
      };

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: AppRadii.fullAll,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
              child: const SizedBox(width: 6, height: 6),
            ),
            const SizedBox(width: 6),
            Text(_label, style: AppTextStyles.caption.copyWith(color: _color)),
          ],
        ),
      ),
    );
  }
}

class _CompletenessBar extends StatelessWidget {
  final MenuDetail menu;
  const _CompletenessBar({required this.menu});

  @override
  Widget build(BuildContext context) {
    final pct = (menu.completeness * 100).round();
    final added = menu.recipes.length;
    final total = menu.totalDays;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$added of $total meals planned',
                style: AppTextStyles.body.copyWith(color: AppColors.ink2)),
            Text('$pct%',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ink2)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: AppRadii.fullAll,
          child: LinearProgressIndicator(
            value: menu.completeness,
            minHeight: 6,
            backgroundColor: AppColors.line2,
            valueColor: AlwaysStoppedAnimation(
              menu.completeness >= 1.0 ? AppColors.ok : AppColors.accent,
            ),
          ),
        ),
      ],
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final MenuRecipe menuRecipe;
  const _RecipeCard({required this.menuRecipe});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: () => context.push('/recipes/${menuRecipe.recipe.recipeId}'),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Photo placeholder
            ClipRRect(
              borderRadius: AppRadii.smAll,
              child: DecoratedBox(
                decoration: BoxDecoration(color: AppColors.line2),
                child: const SizedBox(width: 56, height: 56),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(menuRecipe.recipe.name,
                      style: AppTextStyles.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (menuRecipe.recipe.calorieCount != null) ...[
                    const SizedBox(height: 2),
                    Text('${menuRecipe.recipe.calorieCount} cal',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.ink3)),
                  ],
                  const SizedBox(height: 6),
                  _VotePills(summary: menuRecipe.voteSummary),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: AppColors.ink4, size: 20),
          ],
        ),
      ),
    );
  }
}

class _VotePills extends StatelessWidget {
  final VoteSummary summary;
  const _VotePills({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (summary.yes > 0) _pill('${summary.yes} yes', AppColors.ok),
        if (summary.no > 0) ...[
          const SizedBox(width: 4),
          _pill('${summary.no} no', AppColors.ink3),
        ],
        if (summary.veto > 0) ...[
          const SizedBox(width: 4),
          _pill('${summary.veto} veto', AppColors.danger),
        ],
        if (summary.yes == 0 && summary.no == 0 && summary.veto == 0)
          _pill('no votes', AppColors.ink4),
      ],
    );
  }

  Widget _pill(String label, Color color) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadii.fullAll,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(label,
            style: AppTextStyles.caption.copyWith(color: color)),
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
