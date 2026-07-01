import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/add_recipe/add_recipe_cubit.dart';
import '../../cubits/add_recipe/add_recipe_state.dart';
import '../../data/menus_data_source.dart';
import '../../data/models/recipe.dart';
import '../../data/recipes_data_source.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_typography.dart';
import '../../widgets/states/error_state.dart';

Future<bool> showAddRecipeSheet(
  BuildContext context, {
  required int menuId,
  required Set<int> alreadyAddedRecipeIds,
  required RecipesDataSource recipesDataSource,
  required MenusDataSource menusDataSource,
  required int mealTarget,
}) async {
  final added = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => BlocProvider(
      create: (_) => AddRecipeCubit(
        menuId: menuId,
        recipesDataSource: recipesDataSource,
        menusDataSource: menusDataSource,
        alreadyAddedRecipeIds: alreadyAddedRecipeIds,
      )..load(),
      child: _AddRecipeSheetBody(
        initialCount: alreadyAddedRecipeIds.length,
        mealTarget: mealTarget,
      ),
    ),
  );
  return added ?? false;
}

class _AddRecipeSheetBody extends StatefulWidget {
  final int initialCount;
  final int mealTarget;

  const _AddRecipeSheetBody({
    required this.initialCount,
    required this.mealTarget,
  });

  @override
  State<_AddRecipeSheetBody> createState() => _AddRecipeSheetBodyState();
}

class _AddRecipeSheetBodyState extends State<_AddRecipeSheetBody> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddRecipeCubit, AddRecipeState>(
      builder: (context, state) {
        final newlyAdded =
            state is AddRecipeLoaded ? state.addedRecipeIds.length : 0;
        final totalAdded = widget.initialCount + newlyAdded;
        final targetMet = totalAdded >= widget.mealTarget;

        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              // Handle + header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
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
                    const SizedBox(height: 16),
                    Text('Add a recipe', style: AppTextStyles.h2),
                    const SizedBox(height: 16),
                    // Search bar
                    TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => context.read<AddRecipeCubit>().search(v),
                      style: AppTextStyles.body,
                      decoration: InputDecoration(
                        hintText: 'Search recipes…',
                        hintStyle: AppTextStyles.body.copyWith(color: AppColors.ink4),
                        prefixIcon: Icon(Icons.search, color: AppColors.ink3, size: 20),
                        filled: true,
                        fillColor: AppColors.field,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: AppRadii.smAll,
                          borderSide: BorderSide(color: AppColors.line),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppRadii.smAll,
                          borderSide: BorderSide(color: AppColors.line),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppRadii.smAll,
                          borderSide: BorderSide(color: AppColors.accent, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              // Recipe list
              Expanded(
                child: () {
                  if (state is AddRecipeLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is AddRecipeError) {
                    return ErrorState(
                      message: state.message,
                      onRetry: () => context.read<AddRecipeCubit>().load(),
                    );
                  }
                  if (state is AddRecipeLoaded) {
                    final recipes = state.displayed;
                    if (recipes.isEmpty) {
                      return Center(
                        child: Text('No recipes found',
                            style: AppTextStyles.body.copyWith(color: AppColors.ink3)),
                      );
                    }
                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      itemCount: recipes.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) => _RecipeRow(
                        recipe: recipes[i],
                        added: state.addedRecipeIds.contains(recipes[i].recipeId),
                        onAdd: () =>
                            context.read<AddRecipeCubit>().addRecipe(recipes[i].recipeId),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }(),
              ),
              // "Done" banner appears once the meal target is reached.
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                child: targetMet
                    ? _DoneBanner(totalAdded: totalAdded, target: widget.mealTarget)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DoneBanner extends StatelessWidget {
  final int totalAdded;
  final int target;

  const _DoneBanner({required this.totalAdded, required this.target});

  @override
  Widget build(BuildContext context) {
    final extra = totalAdded - target;
    final label = extra > 0
        ? '$target meals planned · +$extra extra'
        : '$target meals planned';

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(true),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.ok,
              borderRadius: AppRadii.smAll,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Done — $label',
                    style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RecipeRow extends StatelessWidget {
  final Recipe recipe;
  final bool added;
  final VoidCallback onAdd;

  const _RecipeRow({
    required this.recipe,
    required this.added,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.smAll,
        border: Border.all(color: added ? AppColors.ok : AppColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Photo placeholder
            ClipRRect(
              borderRadius: AppRadii.xsAll,
              child: DecoratedBox(
                decoration: BoxDecoration(color: AppColors.line2),
                child: const SizedBox(width: 44, height: 44),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.name,
                    style: AppTextStyles.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (recipe.calorieCount != null)
                    Text(
                      '${recipe.calorieCount} cal',
                      style: AppTextStyles.caption.copyWith(color: AppColors.ink3),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: added
                  ? Icon(Icons.check_circle_rounded,
                      key: const ValueKey('added'), color: AppColors.ok, size: 28)
                  : GestureDetector(
                      key: const ValueKey('add'),
                      onTap: onAdd,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                        child: const SizedBox(
                          width: 28,
                          height: 28,
                          child: Icon(Icons.add, color: Colors.white, size: 18),
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
