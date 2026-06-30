import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../cubits/recipes/recipes_cubit.dart';
import '../../cubits/recipes/recipes_state.dart';
import '../../data/models/recipe.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_typography.dart';
import '../../widgets/cards/app_card.dart';
import '../../widgets/inputs/app_filter_chip.dart';
import '../../data/menus_data_source.dart';
import '../../widgets/states/empty_state.dart';
import '../../widgets/states/error_state.dart';
import '../menus/pick_menu_sheet.dart';

class RecipesScreen extends StatefulWidget {
  final MenusDataSource menusDataSource;
  const RecipesScreen({super.key, required this.menusDataSource});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  bool _searchOpen = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<RecipesCubit>().load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() => _searchOpen = !_searchOpen);
    if (!_searchOpen) {
      _searchController.clear();
      context.read<RecipesCubit>().updateSearch('');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: BlocBuilder<RecipesCubit, RecipesState>(
        builder: (context, state) {
          if (state is RecipesLoading) return const _Loading();
          if (state is RecipesError) {
            return ErrorState(
              message: state.message,
              onRetry: () => context.read<RecipesCubit>().load(),
            );
          }
          if (state is RecipesLoaded) {
            return _Loaded(
              state: state,
              searchOpen: _searchOpen,
              searchController: _searchController,
              onToggleSearch: _toggleSearch,
              menusDataSource: widget.menusDataSource,
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _Loaded extends StatelessWidget {
  final RecipesLoaded state;
  final bool searchOpen;
  final TextEditingController searchController;
  final VoidCallback onToggleSearch;
  final MenusDataSource menusDataSource;

  const _Loaded({
    required this.state,
    required this.searchOpen,
    required this.searchController,
    required this.onToggleSearch,
    required this.menusDataSource,
  });

  @override
  Widget build(BuildContext context) {
    final recipes = state.displayed;

    return CustomScrollView(
      slivers: [
        SliverAppBar.large(
          automaticallyImplyLeading: false,
          backgroundColor: AppColors.bg,
          title: const Text('Recipes'),
          titleTextStyle: AppTextStyles.h2.copyWith(color: AppColors.ink),
          actions: [
            IconButton(
              onPressed: onToggleSearch,
              icon: Icon(
                searchOpen ? LucideIcons.x : LucideIcons.search,
                size: 20,
                color: AppColors.ink2,
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),

        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search field — slides in when open
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 200),
                crossFadeState: searchOpen
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                firstChild: _SearchBar(
                  controller: searchController,
                  onChanged: (q) =>
                      context.read<RecipesCubit>().updateSearch(q),
                ),
                secondChild: const SizedBox.shrink(),
              ),

              // Cuisine filter chips — horizontal scroll
              if (state.cuisines.isNotEmpty) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.cuisines.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final cuisine = state.cuisines[i];
                      return AppFilterChip(
                        label: cuisine.name,
                        selected:
                            state.selectedCuisineId == cuisine.cuisineId,
                        selectedColor: AppColors.teal,
                        verticalPadding: 5,
                        onChanged: (_) => context
                            .read<RecipesCubit>()
                            .selectCuisine(cuisine.cuisineId),
                      );
                    },
                  ),
                ),
              ],

              // Filter pill + active tag indicator
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    _FilterPill(
                      activeTagCount: state.selectedTagId != null ? 1 : 0,
                      onTap: () => _showFilterSheet(context, state),
                    ),
                    if (state.selectedTagId != null) ...[
                      const SizedBox(width: 8),
                      _ActiveTagChip(
                        label: state.tags
                            .firstWhere(
                                (t) => t.dietaryTagId == state.selectedTagId)
                            .name,
                        onRemove: () =>
                            context.read<RecipesCubit>().selectTag(null),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        if (recipes.isEmpty)
          SliverFillRemaining(
            child: EmptyState(
              icon: LucideIcons.utensils,
              title: 'No recipes found',
              body: 'Try adjusting your filters or search term.',
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverList.separated(
              itemCount: recipes.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _RecipeCard(
                recipe: recipes[i],
                menusDataSource: menusDataSource,
              ),
            ),
          ),
      ],
    );
  }

  void _showFilterSheet(BuildContext context, RecipesLoaded state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.xxl),
        ),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<RecipesCubit>(),
        child: _FilterSheet(state: state),
      ),
    );
  }
}

// ---------- Sub-widgets ----------

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.field,
          borderRadius: AppRadii.smAll,
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Icon(LucideIcons.search, size: 16, color: AppColors.ink3),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                autofocus: true,
                style: AppTextStyles.body.copyWith(color: AppColors.ink),
                decoration: InputDecoration(
                  hintText: 'Search recipes…',
                  hintStyle:
                      AppTextStyles.body.copyWith(color: AppColors.ink4),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final int activeTagCount;
  final VoidCallback onTap;

  const _FilterPill({required this.activeTagCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = activeTagCount > 0;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.accent50 : AppColors.surface,
          borderRadius: AppRadii.fullAll,
          border: Border.all(
            color: active ? AppColors.accent : AppColors.line,
          ),
          boxShadow: e0,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.slidersHorizontal,
                size: 14,
                color: active ? AppColors.accentDeep : AppColors.ink2),
            const SizedBox(width: 6),
            Text(
              active ? 'Filters ($activeTagCount)' : 'Filters',
              style: AppTextStyles.label.copyWith(
                color: active ? AppColors.accentDeep : AppColors.ink2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveTagChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _ActiveTagChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onRemove,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.accent50,
          borderRadius: AppRadii.fullAll,
          border: Border.all(color: AppColors.accent200),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.accentDeep)),
              const SizedBox(width: 4),
              Icon(LucideIcons.x, size: 12, color: AppColors.accentDeep),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final MenusDataSource menusDataSource;
  const _RecipeCard({required this.recipe, required this.menusDataSource});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: () => context.push('/recipes/${recipe.recipeId}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo area with "add to menu" button overlaid.
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadii.lg),
                ),
                child: recipe.photoKey != null
                    ? Image.network(
                        recipe.photoKey!,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : _PhotoPlaceholder(name: recipe.name),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: GestureDetector(
                  onTap: () => showPickMenuSheet(
                    context,
                    recipeId: recipe.recipeId,
                    menusDataSource: menusDataSource,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      boxShadow: e1,
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.playlist_add_rounded, size: 20),
                    ),
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(recipe.name,
                    style: AppTextStyles.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                _MetaLine(recipe: recipe),
                if (recipe.tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: recipe.tags
                        .map((t) => _TagPill(label: t.name))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  final String name;
  const _PhotoPlaceholder({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.accent200, AppColors.line2],
        ),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: AppTextStyles.h2.copyWith(
            fontSize: 64,
            color: AppColors.accentDeep.withValues(alpha: 0.35),
          ),
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  final Recipe recipe;
  const _MetaLine({required this.recipe});

  @override
  Widget build(BuildContext context) {
    final parts = [
      if (recipe.calorieCount != null) '${recipe.calorieCount} cal / serving',
      if (recipe.proteinCount != null) '${recipe.proteinCount}g protein',
    ];
    if (parts.isEmpty) return const SizedBox.shrink();
    return Text(
      parts.join(' · '),
      style: AppTextStyles.caption.copyWith(color: AppColors.ink3),
    );
  }
}

class _TagPill extends StatelessWidget {
  final String label;
  const _TagPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.teal50,
        borderRadius: AppRadii.fullAll,
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(label,
            style: AppTextStyles.caption.copyWith(color: AppColors.tealDeep)),
      ),
    );
  }
}

class _FilterSheet extends StatelessWidget {
  final RecipesLoaded state;
  const _FilterSheet({required this.state});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: AppRadii.fullAll,
                ),
                child: const SizedBox(width: 36, height: 4),
              ),
            ),
            const SizedBox(height: 20),
            Text('Dietary filters', style: AppTextStyles.h2),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: state.tags.map((tag) {
                final selected = state.selectedTagId == tag.dietaryTagId;
                return AppFilterChip(
                  label: tag.name,
                  selected: selected,
                  onChanged: (_) {
                    context
                        .read<RecipesCubit>()
                        .selectTag(tag.dietaryTagId);
                    Navigator.of(context).pop();
                  },
                );
              }).toList(),
            ),
            if (state.selectedTagId != null) ...[
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  context.read<RecipesCubit>().selectTag(null);
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Clear filters',
                  style:
                      AppTextStyles.label.copyWith(color: AppColors.accentDeep),
                ),
              ),
            ],
          ],
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
        SliverAppBar.large(title: Text('Recipes')),
        SliverFillRemaining(
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
    );
  }
}
