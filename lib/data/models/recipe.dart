import 'package:equatable/equatable.dart';

class DietaryTag extends Equatable {
  final int dietaryTagId;
  final String name;

  const DietaryTag({required this.dietaryTagId, required this.name});

  factory DietaryTag.fromJson(Map<String, dynamic> json) => DietaryTag(
        dietaryTagId: json['dietary_tag_id'] as int,
        name: json['name'] as String,
      );

  @override
  List<Object?> get props => [dietaryTagId, name];
}

class Cuisine extends Equatable {
  final int cuisineId;
  final String name;

  const Cuisine({required this.cuisineId, required this.name});

  factory Cuisine.fromJson(Map<String, dynamic> json) => Cuisine(
        cuisineId: json['cuisine_id'] as int,
        name: json['name'] as String,
      );

  @override
  List<Object?> get props => [cuisineId, name];
}

class RecipeIngredient extends Equatable {
  final int recipeIngredientId;
  final String name;
  final double? portionSize;
  final String? portionUnit;
  final int? calories;

  const RecipeIngredient({
    required this.recipeIngredientId,
    required this.name,
    this.portionSize,
    this.portionUnit,
    this.calories,
  });

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) =>
      RecipeIngredient(
        recipeIngredientId: json['recipe_ingredient_id'] as int,
        name: (json['ingredient'] as Map<String, dynamic>)['name'] as String,
        portionSize: (json['portion_size'] as num?)?.toDouble(),
        portionUnit: json['portion_unit'] as String?,
        calories: json['calories'] as int?,
      );

  @override
  List<Object?> get props =>
      [recipeIngredientId, name, portionSize, portionUnit, calories];
}

class RecipeStep extends Equatable {
  final int recipeStepId;
  final int stepNumber;
  final String instructions;

  const RecipeStep({
    required this.recipeStepId,
    required this.stepNumber,
    required this.instructions,
  });

  factory RecipeStep.fromJson(Map<String, dynamic> json) => RecipeStep(
        recipeStepId: json['recipe_step_id'] as int,
        stepNumber: json['step_number'] as int,
        instructions: json['instructions'] as String,
      );

  @override
  List<Object?> get props => [recipeStepId, stepNumber, instructions];
}

class Recipe extends Equatable {
  final int recipeId;
  final String name;
  final String? description;
  final int? calorieCount;
  final int? proteinCount;
  final String? photoKey;
  final String? sourceUrl;
  final Cuisine? cuisine;
  final List<DietaryTag> tags;
  final List<RecipeIngredient> ingredients;
  final List<RecipeStep> steps;

  const Recipe({
    required this.recipeId,
    required this.name,
    this.description,
    this.calorieCount,
    this.proteinCount,
    this.photoKey,
    this.sourceUrl,
    this.cuisine,
    this.tags = const [],
    this.ingredients = const [],
    this.steps = const [],
  });

  factory Recipe.fromJson(Map<String, dynamic> json) => Recipe(
        recipeId: json['recipe_id'] as int,
        name: json['name'] as String,
        description: json['description'] as String?,
        calorieCount: json['calorie_count'] as int?,
        proteinCount: json['protein_count'] as int?,
        photoKey: json['photo_key'] as String?,
        sourceUrl: json['source_url'] as String?,
        cuisine: json['cuisine'] != null
            ? Cuisine.fromJson(json['cuisine'] as Map<String, dynamic>)
            : null,
        tags: (json['tags'] as List<dynamic>? ?? [])
            .map((e) => DietaryTag.fromJson(e as Map<String, dynamic>))
            .toList(),
        ingredients: (json['ingredients'] as List<dynamic>? ?? [])
            .map((e) => RecipeIngredient.fromJson(e as Map<String, dynamic>))
            .toList(),
        steps: (json['steps'] as List<dynamic>? ?? [])
            .map((e) => RecipeStep.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  List<Object?> get props =>
      [recipeId, name, description, calorieCount, proteinCount, photoKey, sourceUrl, cuisine, tags, ingredients, steps];
}
