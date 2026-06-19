import 'package:equatable/equatable.dart';
import '../../data/models/recipe.dart';

abstract class RecipeDetailState extends Equatable {
  const RecipeDetailState();
  @override
  List<Object?> get props => [];
}

class RecipeDetailLoading extends RecipeDetailState {
  const RecipeDetailLoading();
}

class RecipeDetailLoaded extends RecipeDetailState {
  final Recipe recipe;
  const RecipeDetailLoaded(this.recipe);
  @override
  List<Object?> get props => [recipe];
}

class RecipeDetailError extends RecipeDetailState {
  final String message;
  const RecipeDetailError(this.message);
  @override
  List<Object?> get props => [message];
}
