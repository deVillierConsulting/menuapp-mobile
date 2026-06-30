import 'package:equatable/equatable.dart';
import '../../data/models/recipe.dart';

abstract class AddRecipeState extends Equatable {
  const AddRecipeState();
  @override
  List<Object?> get props => [];
}

class AddRecipeLoading extends AddRecipeState {
  const AddRecipeLoading();
}

class AddRecipeLoaded extends AddRecipeState {
  final List<Recipe> allRecipes;
  final Set<int> addedRecipeIds;
  final String query;

  const AddRecipeLoaded({
    required this.allRecipes,
    required this.addedRecipeIds,
    this.query = '',
  });

  List<Recipe> get displayed {
    if (query.isEmpty) return allRecipes;
    final q = query.toLowerCase();
    return allRecipes.where((r) => r.name.toLowerCase().contains(q)).toList();
  }

  AddRecipeLoaded copyWith({Set<int>? addedRecipeIds, String? query}) =>
      AddRecipeLoaded(
        allRecipes: allRecipes,
        addedRecipeIds: addedRecipeIds ?? this.addedRecipeIds,
        query: query ?? this.query,
      );

  @override
  List<Object?> get props => [allRecipes, addedRecipeIds, query];
}

class AddRecipeError extends AddRecipeState {
  final String message;
  const AddRecipeError(this.message);
  @override
  List<Object?> get props => [message];
}
