import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../data/menus_data_source.dart';
import '../../session/app_session.dart';
import '../../data/recipes_data_source.dart';
import '../../widgets/nav/app_page_header.dart';
import '../../widgets/states/empty_state.dart';
import '../../widgets/states/error_state.dart';
import 'add_recipe_sheet.dart';

class MenuDetailScreen extends StatefulWidget {
  final int menuId;
  final MenusDataSource menusDataSource;
  final RecipesDataSource recipesDataSource;
  final AppSession session;
  const MenuDetailScreen({
    super.key,
    required this.menuId,
    required this.menusDataSource,
    required this.recipesDataSource,
    required this.session,
  });

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
            return _Loaded(
              menu: state.menu,
              menusDataSource: widget.menusDataSource,
              recipesDataSource: widget.recipesDataSource,
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: BlocBuilder<MenuDetailCubit, MenuDetailState>(
        builder: (context, state) {
          if (state is! MenuDetailLoaded) return const SizedBox.shrink();
          if (state.menu.status != MenuStatus.active) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: () async {
              final alreadyAdded = state.menu.recipes
                  .map((mr) => mr.recipe.recipeId)
                  .toSet();
              await showAddRecipeSheet(
                context,
                menuId: widget.menuId,
                alreadyAddedRecipeIds: alreadyAdded,
                recipesDataSource: widget.recipesDataSource,
                menusDataSource: widget.menusDataSource,
                session: widget.session,
              );
              if (context.mounted) {
                context.read<MenuDetailCubit>().load();
              }
            },
            backgroundColor: AppColors.accent,
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text('Add recipe',
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
          );
        },
      ),
    );
  }
}

class _Loaded extends StatelessWidget {
  final MenuDetail menu;
  final MenusDataSource menusDataSource;
  final RecipesDataSource recipesDataSource;
  const _Loaded({
    required this.menu,
    required this.menusDataSource,
    required this.recipesDataSource,
  });

  String get _title => menu.name ?? '${_fmt(menu.startDate)} – ${_fmt(menu.endDate)}';

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
            if (menu.status == MenuStatus.final_ && menu.recipes.isNotEmpty) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => context.push('/menus/${menu.menuId}/grocery-list'),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.ok.withValues(alpha: 0.1),
                    borderRadius: AppRadii.smAll,
                    border: Border.all(color: AppColors.ok.withValues(alpha: 0.3)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.shopping_cart_outlined, color: AppColors.ok, size: 18),
                        const SizedBox(width: 10),
                        Text('View grocery list',
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ok)),
                        const Spacer(),
                        Icon(Icons.chevron_right_rounded, color: AppColors.ok, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ],
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
                    child: _RecipeCard(
                      menuRecipe: mr,
                      votingEnabled: menu.status == MenuStatus.active,
                    ),
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
        MenuStatus.active => 'Planning',
        MenuStatus.final_ => 'This week',
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
    final added = menu.recipes.length;
    final target = menu.mealTarget;
    final isComplete = added >= target;
    final extra = added - target;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isComplete
                  ? (extra > 0 ? '$target meals planned · +$extra extra' : '$target meals planned')
                  : '$added of $target meals planned',
              style: AppTextStyles.body.copyWith(color: AppColors.ink2),
            ),
            if (isComplete)
              Text('✓', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ok))
            else
              Text(
                '${((added / target) * 100).round()}%',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.ink2),
              ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: AppRadii.fullAll,
          child: LinearProgressIndicator(
            value: isComplete ? 1.0 : added / target,
            minHeight: 6,
            backgroundColor: AppColors.line2,
            valueColor: AlwaysStoppedAnimation(
              isComplete ? AppColors.ok : AppColors.accent,
            ),
          ),
        ),
        if (isComplete && menu.status == MenuStatus.active) ...[
          const SizedBox(height: 16),
          _FinalizeButton(),
        ],
      ],
    );
  }
}

class _FinalizeButton extends StatelessWidget {
  const _FinalizeButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Finalize this menu?'),
            content: const Text(
              'This locks in the recipes and generates your grocery list. You won\'t be able to add or remove recipes after this.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Not yet'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text('Finalize',
                    style: TextStyle(color: AppColors.accent)),
              ),
            ],
          ),
        );
        if (confirmed == true && context.mounted) {
          await context.read<MenuDetailCubit>().finalizeMenu();
          if (context.mounted) {
            context.push('/menus/${context.read<MenuDetailCubit>().menuId}/grocery-list');
          }
        }
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: AppRadii.smAll,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('Finalize menu & get grocery list',
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

// Swipe right → yes, swipe left → no, veto button explicit on card.
// Drag past _kThreshold to commit a vote; release before it to snap back.
const double _kThreshold = 100.0;

class _RecipeCard extends StatefulWidget {
  final MenuRecipe menuRecipe;
  final bool votingEnabled;
  const _RecipeCard({required this.menuRecipe, this.votingEnabled = true});

  @override
  State<_RecipeCard> createState() => _RecipeCardState();
}

class _RecipeCardState extends State<_RecipeCard>
    with SingleTickerProviderStateMixin {
  double _dragX = 0;
  late final AnimationController _snapCtrl;
  late Animation<double> _snapAnim;

  @override
  void initState() {
    super.initState();
    _snapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _snapCtrl.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    setState(() => _dragX += d.delta.dx);
  }

  void _onDragEnd(DragEndDetails d) {
    if (_dragX.abs() >= _kThreshold) {
      final vote = _dragX > 0 ? VoteValue.yes : VoteValue.no;
      HapticFeedback.mediumImpact();
      context.read<MenuDetailCubit>().castVote(
            widget.menuRecipe.menuRecipeId,
            vote,
          );
    }
    // Snap back to centre regardless.
    _snapAnim = Tween<double>(begin: _dragX, end: 0).animate(
      CurvedAnimation(parent: _snapCtrl, curve: Curves.elasticOut),
    )..addListener(() => setState(() => _dragX = _snapAnim.value));
    _snapCtrl.forward(from: 0);
  }

  // How far along (0→1) the drag is toward the threshold.
  double get _progress => (_dragX.abs() / _kThreshold).clamp(0.0, 1.0);
  bool get _goingRight => _dragX >= 0;

  @override
  Widget build(BuildContext context) {
    final userVote = widget.menuRecipe.voteSummary.userVote;

    return GestureDetector(
      onHorizontalDragUpdate: widget.votingEnabled ? _onDragUpdate : null,
      onHorizontalDragEnd: widget.votingEnabled ? _onDragEnd : null,
      onTap: () => context.push('/recipes/${widget.menuRecipe.recipe.recipeId}'),
      child: Transform.translate(
        offset: Offset(_dragX, 0),
        child: Stack(
          children: [
            _CardContent(
              menuRecipe: widget.menuRecipe,
              userVote: userVote,
              votingEnabled: widget.votingEnabled,
            ),

            // Coloured overlay fades in as you drag.
            if (_dragX != 0)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: AppRadii.lgAll,
                  child: AnimatedContainer(
                    duration: Duration.zero,
                    color: (_goingRight ? AppColors.ok : AppColors.danger)
                        .withValues(alpha: _progress * 0.18),
                    child: Align(
                      alignment: _goingRight
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Icon(
                          _goingRight
                              ? LucideIcons.check
                              : LucideIcons.x,
                          color: (_goingRight ? AppColors.ok : AppColors.danger)
                              .withValues(alpha: _progress),
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CardContent extends StatelessWidget {
  final MenuRecipe menuRecipe;
  final VoteValue? userVote;
  final bool votingEnabled;
  const _CardContent({
    required this.menuRecipe,
    required this.userVote,
    this.votingEnabled = true,
  });

  // Border tint shows the user's committed vote at rest.
  Color? get _voteBorderColor => switch (userVote) {
        VoteValue.yes  => AppColors.ok,
        VoteValue.no   => AppColors.ink3,
        VoteValue.veto => AppColors.danger,
        null           => null,
      };

  @override
  Widget build(BuildContext context) {
    final border = _voteBorderColor;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.lgAll,
        border: Border.all(
          color: border ?? AppColors.line,
          width: border != null ? 1.5 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0D1C1917), offset: Offset(0, 1), blurRadius: 2),
          BoxShadow(
              color: Color(0x0D1C1917), offset: Offset(0, 2), blurRadius: 6),
        ],
      ),
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
            if (votingEnabled) ...[
              const SizedBox(width: 8),
              _VetoButton(
                active: userVote == VoteValue.veto,
                onTap: () => context
                    .read<MenuDetailCubit>()
                    .castVote(menuRecipe.menuRecipeId, VoteValue.veto),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _VetoButton extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  const _VetoButton({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.heavyImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: active ? AppColors.dangerBg : AppColors.field,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            LucideIcons.ban,
            size: 15,
            color: active ? AppColors.danger : AppColors.ink4,
          ),
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
