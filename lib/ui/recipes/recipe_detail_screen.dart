import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/recipe_detail/recipe_detail_cubit.dart';
import '../../cubits/recipe_detail/recipe_detail_state.dart';
import '../../data/models/recipe.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radii.dart';
import '../../theme/app_typography.dart';
import '../../data/menus_data_source.dart';
import '../../widgets/states/error_state.dart';
import '../menus/pick_menu_sheet.dart';

class RecipeDetailScreen extends StatefulWidget {
  final int recipeId;
  final MenusDataSource menusDataSource;
  const RecipeDetailScreen({
    super.key,
    required this.recipeId,
    required this.menusDataSource,
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<RecipeDetailCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: BlocBuilder<RecipeDetailCubit, RecipeDetailState>(
        builder: (context, state) {
          if (state is RecipeDetailLoading) return const _Loading();
          if (state is RecipeDetailError) {
            return ErrorState(
              message: state.message,
              onRetry: () => context.read<RecipeDetailCubit>().load(),
            );
          }
          if (state is RecipeDetailLoaded) return _Loaded(
            recipe: state.recipe,
            menusDataSource: widget.menusDataSource,
          );
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _Loaded extends StatelessWidget {
  final Recipe recipe;
  final MenusDataSource menusDataSource;
  const _Loaded({required this.recipe, required this.menusDataSource});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Hero photo slot — renders a placeholder until photo_key is wired to CDN.
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          backgroundColor: AppColors.surface,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            color: AppColors.accent,
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.playlist_add_rounded),
              color: AppColors.accent,
              tooltip: 'Add to menu',
              onPressed: () => showPickMenuSheet(
                context,
                recipeId: recipe.recipeId,
                menusDataSource: menusDataSource,
              ),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: recipe.photoKey != null
                ? Image.network(recipe.photoKey!, fit: BoxFit.cover)
                : _PhotoPlaceholder(name: recipe.name),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 48),
          sliver: SliverList.list(children: [
            // Title + meta row
            Text(recipe.name, style: AppTextStyles.h2),
            const SizedBox(height: 8),
            _MetaRow(recipe: recipe),

            // Description
            if (recipe.description != null) ...[
              const SizedBox(height: 16),
              Text(recipe.description!,
                  style: AppTextStyles.body.copyWith(color: AppColors.ink2)),
            ],

            // Dietary tags
            if (recipe.tags.isNotEmpty) ...[
              const SizedBox(height: 20),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: recipe.tags
                    .map((t) => _TagChip(label: t.name))
                    .toList(),
              ),
            ],

            // Ingredients
            if (recipe.ingredients.isNotEmpty) ...[
              const SizedBox(height: 28),
              Text('Ingredients',
                  style: AppTextStyles.label.copyWith(color: AppColors.ink3)),
              const SizedBox(height: 12),
              ...recipe.ingredients.map((i) => _IngredientRow(ingredient: i)),
            ],

            // Steps
            if (recipe.steps.isNotEmpty) ...[
              const SizedBox(height: 28),
              Text('Instructions',
                  style: AppTextStyles.label.copyWith(color: AppColors.ink3)),
              const SizedBox(height: 12),
              ...recipe.steps.map((s) => _StepRow(step: s)),
            ],

            // Source link
            if (recipe.sourceUrl != null) ...[
              const SizedBox(height: 24),
              Text('Source',
                  style: AppTextStyles.caption.copyWith(color: AppColors.ink3)),
              const SizedBox(height: 4),
              Text(recipe.sourceUrl!,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.accent,
                                decoration: TextDecoration.underline)),
            ],
          ]),
        ),
      ],
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  final String name;
  const _PhotoPlaceholder({required this.name});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
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
            fontSize: 72,
            color: AppColors.accentDeep.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final Recipe recipe;
  const _MetaRow({required this.recipe});

  @override
  Widget build(BuildContext context) {
    final parts = [
      // if (recipe.cuisine != null) recipe.cuisine!.name,
      if (recipe.calorieCount != null) '${recipe.calorieCount} cal',
      if (recipe.proteinCount != null) '${recipe.proteinCount}g protein',
    ];
    if (parts.isEmpty) return const SizedBox.shrink();
    return Text(
      parts.join(' · '),
      style: AppTextStyles.body.copyWith(color: AppColors.ink3),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.field,
        borderRadius: AppRadii.fullAll,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.ink2)),
      ),
    );
  }
}

class _IngredientRow extends StatelessWidget {
  final RecipeIngredient ingredient;
  const _IngredientRow({required this.ingredient});

  String get _amount {
    if (ingredient.portionSize == null && ingredient.portionUnit == null) {
      return '';
    }
    final size = ingredient.portionSize != null
        ? (ingredient.portionSize! % 1 == 0
            ? ingredient.portionSize!.toInt().toString()
            : ingredient.portionSize!.toString())
        : '';
    final unit = ingredient.portionUnit ?? '';
    return '$size $unit'.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.line2,
              shape: BoxShape.circle,
            ),
            child: const SizedBox(width: 6, height: 6),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(ingredient.name,
                style: AppTextStyles.body.copyWith(color: AppColors.ink)),
          ),
          if (_amount.isNotEmpty)
            Text(_amount,
                style: AppTextStyles.body.copyWith(color: AppColors.ink3)),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final RecipeStep step;
  const _StepRow({required this.step});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step number bubble
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
            child: SizedBox(
              width: 26,
              height: 26,
              child: Center(
                child: Text(
                  '${step.stepNumber}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.surface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(step.instructions,
                  style: AppTextStyles.body.copyWith(color: AppColors.ink)),
            ),
          ),
        ],
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
        SliverAppBar(expandedHeight: 280, pinned: true),
        SliverFillRemaining(
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
    );
  }
}
