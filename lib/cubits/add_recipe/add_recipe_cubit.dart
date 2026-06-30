import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/menus_data_source.dart';
import '../../data/recipes_data_source.dart';
import 'add_recipe_state.dart';

class AddRecipeCubit extends Cubit<AddRecipeState> {
  final RecipesDataSource _recipesDataSource;
  final MenusDataSource _menusDataSource;
  final int menuId;
  final Set<int> _initiallyAdded;

  AddRecipeCubit({
    required this.menuId,
    required RecipesDataSource recipesDataSource,
    required MenusDataSource menusDataSource,
    required Set<int> alreadyAddedRecipeIds,
  })  : _recipesDataSource = recipesDataSource,
        _menusDataSource = menusDataSource,
        _initiallyAdded = alreadyAddedRecipeIds,
        super(const AddRecipeLoading());

  Future<void> load() async {
    emit(const AddRecipeLoading());
    try {
      final recipes = await _recipesDataSource.listRecipes();
      emit(AddRecipeLoaded(
        allRecipes: recipes,
        addedRecipeIds: Set.from(_initiallyAdded),
      ));
    } catch (e) {
      emit(AddRecipeError(e.toString()));
    }
  }

  void search(String query) {
    final current = state;
    if (current is! AddRecipeLoaded) return;
    emit(current.copyWith(query: query));
  }

  Future<void> addRecipe(int recipeId) async {
    final current = state;
    if (current is! AddRecipeLoaded) return;
    emit(current.copyWith(addedRecipeIds: {...current.addedRecipeIds, recipeId}));
    try {
      await _menusDataSource.addRecipeToMenu(
        menuId: menuId,
        recipeId: recipeId,
      );
    } catch (_) {
      final ids = {...current.addedRecipeIds}..remove(recipeId);
      emit(current.copyWith(addedRecipeIds: ids));
    }
  }
}
