import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/recipes_data_source.dart';
import 'recipes_state.dart';

class RecipesCubit extends Cubit<RecipesState> {
  final RecipesDataSource _dataSource;

  RecipesCubit({required RecipesDataSource dataSource})
      : _dataSource = dataSource,
        super(const RecipesLoading());

  Future<void> load() async {
    emit(const RecipesLoading());
    try {
      final (recipes, cuisines, tags) = await (
        _dataSource.listRecipes(),
        _dataSource.listCuisines(),
        _dataSource.listDietaryTags(),
      ).wait;
      emit(RecipesLoaded(recipes: recipes, cuisines: cuisines, tags: tags));
    } catch (e) {
      emit(RecipesError(e.toString()));
    }
  }

  Future<void> selectCuisine(int? cuisineId) async {
    final current = state;
    if (current is! RecipesLoaded) return;

    // Toggle off if already selected.
    final nextId =
        current.selectedCuisineId == cuisineId ? null : cuisineId;

    emit(current.copyWith(
      clearCuisine: nextId == null,
      selectedCuisineId: nextId,
      // Keep tag filter but clear search when changing cuisine.
      searchQuery: '',
    ));

    try {
      final recipes = await _dataSource.listRecipes(
        cuisineId: nextId,
        tagId: current.selectedTagId,
      );
      final loaded = state;
      if (loaded is RecipesLoaded) {
        emit(loaded.copyWith(recipes: recipes));
      }
    } catch (e) {
      emit(RecipesError(e.toString()));
    }
  }

  Future<void> selectTag(int? tagId) async {
    final current = state;
    if (current is! RecipesLoaded) return;

    final nextId = current.selectedTagId == tagId ? null : tagId;

    emit(current.copyWith(
      clearTag: nextId == null,
      selectedTagId: nextId,
      searchQuery: '',
    ));

    try {
      final recipes = await _dataSource.listRecipes(
        cuisineId: current.selectedCuisineId,
        tagId: nextId,
      );
      final loaded = state;
      if (loaded is RecipesLoaded) {
        emit(loaded.copyWith(recipes: recipes));
      }
    } catch (e) {
      emit(RecipesError(e.toString()));
    }
  }

  void updateSearch(String query) {
    final current = state;
    if (current is! RecipesLoaded) return;
    emit(current.copyWith(searchQuery: query));
  }
}
