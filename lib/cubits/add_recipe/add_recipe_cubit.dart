import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/menus_data_source.dart';
import '../../data/models/recipe.dart';
import '../../data/recipes_data_source.dart';

// ---------- State ----------

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
  final Set<int> addedRecipeIds; // already in this menu
  final String query;

  const AddRecipeLoaded({
    required this.allRecipes,
    required this.addedRecipeIds,
    this.query = '',
  });

  List<Recipe> get displayed {
    if (query.isEmpty) return allRecipes;
    final q = query.toLowerCase();
    return allRecipes
        .where((r) => r.name.toLowerCase().contains(q))
        .toList();
  }

  AddRecipeLoaded copyWith({
    Set<int>? addedRecipeIds,
    String? query,
  }) =>
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

// ---------- Cubit ----------

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
    // Optimistically mark as added so the UI responds immediately.
    emit(current.copyWith(
      addedRecipeIds: {...current.addedRecipeIds, recipeId},
    ));
    try {
      await _menusDataSource.addRecipeToMenu(
        menuId: menuId,
        recipeId: recipeId,
      );
    } catch (_) {
      // Revert on failure.
      final ids = {...current.addedRecipeIds}..remove(recipeId);
      emit(current.copyWith(addedRecipeIds: ids));
    }
  }
}
