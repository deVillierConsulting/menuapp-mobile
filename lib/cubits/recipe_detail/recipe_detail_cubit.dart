import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/recipes_data_source.dart';
import 'recipe_detail_state.dart';

class RecipeDetailCubit extends Cubit<RecipeDetailState> {
  final RecipesDataSource _dataSource;
  final int recipeId;

  RecipeDetailCubit({required RecipesDataSource dataSource, required this.recipeId})
      : _dataSource = dataSource,
        super(const RecipeDetailLoading());

  Future<void> load() async {
    emit(const RecipeDetailLoading());
    try {
      final recipe = await _dataSource.getRecipe(recipeId);
      emit(RecipeDetailLoaded(recipe));
    } catch (e) {
      emit(RecipeDetailError(e.toString()));
    }
  }
}
