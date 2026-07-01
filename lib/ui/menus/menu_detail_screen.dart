import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../cubits/menu_detail/menu_detail_cubit.dart';
import '../../cubits/menu_detail/menu_detail_state.dart';
import '../../cubits/shop/shop_cubit.dart';
import '../../data/models/menu.dart';
import '../../data/models/menu_detail.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_typography.dart';
import '../../data/menus_data_source.dart';
import '../../data/recipes_data_source.dart';
import '../../widgets/nav/app_page_header.dart';
import '../../widgets/states/empty_state.dart';
import '../../widgets/states/error_state.dart';
import 'add_recipe_sheet.dart';

class MenuDetailScreen extends StatefulWidget {
  final int menuId;
  final MenusDataSource menusDataSource;
  final RecipesDataSource recipesDataSource;
  const MenuDetailScreen({
    super.key,
    required this.menuId,
    required this.menusDataSource,
    required this.recipesDataSource,
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
                mealTarget: state.menu.mealTarget,
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
            context.read<ShopCubit>().load();
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

// Swipe right → green panel grows from right edge → tap check to vote yes.
// Swipe left  → red panel grows from left edge → tap X to vote no.
// Releasing past 40% of panel width holds the panel open.
// Tap the card content (not the button) to dismiss without voting.
const double _kPanelMax = 72.0;  // max panel width
const double _kDragMax  = 110.0; // drag distance that reaches full panel

class _RecipeCard extends StatefulWidget {
  final MenuRecipe menuRecipe;
  final bool votingEnabled;
  const _RecipeCard({required this.menuRecipe, this.votingEnabled = true});

  @override
  State<_RecipeCard> createState() => _RecipeCardState();
}

class _RecipeCardState extends State<_RecipeCard>
    with SingleTickerProviderStateMixin {
  // _dragX drives panel width. Positive = right (yes), negative = left (no).
  double _dragX = 0;
  bool   _held  = false; // panel is held open after finger lift
  late final AnimationController _animCtrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (_held) return;
    setState(() => _dragX = (_dragX + d.delta.dx).clamp(-_kDragMax, _kDragMax));
  }

  void _onDragEnd(DragEndDetails d) {
    final ratio = _dragX.abs() / _kDragMax;
    if (ratio >= 0.4) {
      // Snap to full width and hold.
      final target = _dragX > 0 ? _kDragMax : -_kDragMax;
      _animate(to: target);
      setState(() => _held = true);
    } else {
      _dismiss();
    }
  }

  void _dismiss() {
    setState(() => _held = false);
    _animate(to: 0);
  }

  void _animate({required double to}) {
    _animCtrl.stop();
    _anim = Tween<double>(begin: _dragX, end: to)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut))
      ..addListener(() => setState(() => _dragX = _anim.value));
    _animCtrl.forward(from: 0);
  }

  void _commitVote(VoteValue vote) {
    HapticFeedback.mediumImpact();
    context.read<MenuDetailCubit>().castVote(
        widget.menuRecipe.menuRecipeId, vote);
    _dismiss();
  }

  double get _panelWidth =>
      (_dragX.abs() / _kDragMax * _kPanelMax).clamp(0.0, _kPanelMax);
  double get _iconOpacity =>
      ((_panelWidth / _kPanelMax - 0.3) / 0.7).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final userVote  = widget.menuRecipe.voteSummary.userVote;
    final showRight = widget.votingEnabled && _dragX > 0;
    final showLeft  = widget.votingEnabled && _dragX < 0;
    final pw        = _panelWidth;

    return GestureDetector(
      onHorizontalDragUpdate: widget.votingEnabled ? _onDragUpdate : null,
      onHorizontalDragEnd:   widget.votingEnabled ? _onDragEnd   : null,
      onTap: () {
        if (_held) { _dismiss(); return; }
        context.push('/recipes/${widget.menuRecipe.recipe.recipeId}');
      },
      child: Stack(
        children: [
          // Card content with extra padding on whichever side has the panel,
          // so the title/photo compress rather than hiding under the panel.
          _CardContent(
            menuRecipe: widget.menuRecipe,
            userVote: userVote,
            votingEnabled: widget.votingEnabled,
            extraRightPadding: showRight ? pw : 0,
            extraLeftPadding:  showLeft  ? pw : 0,
          ),

          // Yes panel — right edge.
          if (showRight && pw > 0)
            Positioned(
              right: 0, top: 0, bottom: 0,
              child: GestureDetector(
                onTap: () => _commitVote(VoteValue.yes),
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topRight:    AppRadii.lgAll.topRight,
                    bottomRight: AppRadii.lgAll.bottomRight,
                  ),
                  child: SizedBox(
                    width: pw,
                    child: ColoredBox(
                      color: AppColors.ok,
                      child: Center(
                        child: Opacity(
                          opacity: _iconOpacity,
                          child: const Icon(LucideIcons.check,
                              color: Colors.white, size: 22),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // No panel — left edge.
          if (showLeft && pw > 0)
            Positioned(
              left: 0, top: 0, bottom: 0,
              child: GestureDetector(
                onTap: () => _commitVote(VoteValue.no),
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft:    AppRadii.lgAll.topLeft,
                    bottomLeft: AppRadii.lgAll.bottomLeft,
                  ),
                  child: SizedBox(
                    width: pw,
                    child: ColoredBox(
                      color: AppColors.danger,
                      child: Center(
                        child: Opacity(
                          opacity: _iconOpacity,
                          child: const Icon(LucideIcons.x,
                              color: Colors.white, size: 22),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CardContent extends StatelessWidget {
  final MenuRecipe menuRecipe;
  final VoteValue? userVote;
  final bool votingEnabled;
  final double extraRightPadding;
  final double extraLeftPadding;
  const _CardContent({
    required this.menuRecipe,
    required this.userVote,
    this.votingEnabled = true,
    this.extraRightPadding = 0,
    this.extraLeftPadding  = 0,
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
        padding: EdgeInsets.fromLTRB(
          14 + extraLeftPadding, 14, 14 + extraRightPadding, 14),
        child: Row(
          children: [
            // Recipe thumbnail
            ClipRRect(
              borderRadius: AppRadii.smAll,
              child: SizedBox(
                width: 56,
                height: 56,
                child: menuRecipe.recipe.photoKey != null
                    ? Image.network(
                        menuRecipe.recipe.photoKey!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => const ColoredBox(
                            color: AppColors.line2),
                      )
                    : const ColoredBox(color: AppColors.line2),
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
