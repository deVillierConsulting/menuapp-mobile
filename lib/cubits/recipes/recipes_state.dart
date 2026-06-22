import 'package:equatable/equatable.dart';
import '../../data/models/recipe.dart';

abstract class RecipesState extends Equatable {
  const RecipesState();
  @override
  List<Object?> get props => [];
}

class RecipesLoading extends RecipesState {
  const RecipesLoading();
}

class RecipesLoaded extends RecipesState {
  final List<Recipe> recipes;
  final List<Cuisine> cuisines;
  final List<DietaryTag> tags;
  final int? selectedCuisineId;
  final int? selectedTagId;
  final String searchQuery;

  const RecipesLoaded({
    required this.recipes,
    required this.cuisines,
    required this.tags,
    this.selectedCuisineId,
    this.selectedTagId,
    this.searchQuery = '',
  });

  // Client-side search applied on top of the server-filtered list.
  List<Recipe> get displayed {
    if (searchQuery.isEmpty) return recipes;
    final q = searchQuery.toLowerCase();
    return recipes
        .where((r) =>
            r.name.toLowerCase().contains(q) ||
            (r.description?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  RecipesLoaded copyWith({
    List<Recipe>? recipes,
    List<Cuisine>? cuisines,
    List<DietaryTag>? tags,
    int? selectedCuisineId,
    bool clearCuisine = false,
    int? selectedTagId,
    bool clearTag = false,
    String? searchQuery,
  }) =>
      RecipesLoaded(
        recipes: recipes ?? this.recipes,
        cuisines: cuisines ?? this.cuisines,
        tags: tags ?? this.tags,
        selectedCuisineId:
            clearCuisine ? null : (selectedCuisineId ?? this.selectedCuisineId),
        selectedTagId: clearTag ? null : (selectedTagId ?? this.selectedTagId),
        searchQuery: searchQuery ?? this.searchQuery,
      );

  @override
  List<Object?> get props =>
      [recipes, cuisines, tags, selectedCuisineId, selectedTagId, searchQuery];
}

class RecipesError extends RecipesState {
  final String message;
  const RecipesError(this.message);
  @override
  List<Object?> get props => [message];
}
