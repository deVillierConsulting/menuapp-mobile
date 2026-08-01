import 'package:equatable/equatable.dart';
import '../../data/models/active_menu_summary.dart';
import '../../data/models/menu_detail.dart';

abstract class HomeState extends Equatable {
  const HomeState();
  @override
  List<Object?> get props => [];
}

class HomeLoading extends HomeState {
  const HomeLoading();
}

/// User has no groups yet.
class HomeNoGroup extends HomeState {
  const HomeNoGroup();
}

/// User has groups but no active menu for this week.
class HomeNoMenu extends HomeState {
  final List<ActiveMenuSummary> menus;
  final ActiveMenuSummary? selected;
  const HomeNoMenu({required this.menus, this.selected});
  @override
  List<Object?> get props => [menus, selected];
}

/// The active menu has unvoted recipes — show the card stack.
class HomeVoting extends HomeState {
  final List<ActiveMenuSummary> menus;
  final ActiveMenuSummary selected;
  final MenuDetail detail;

  const HomeVoting({
    required this.menus,
    required this.selected,
    required this.detail,
  });

  /// Recipes the current user hasn't voted on yet.
  List<MenuRecipe> get pending =>
      detail.recipes.where((r) => r.voteSummary.userVote == null).toList();

  /// Recipes the user has already voted on.
  List<MenuRecipe> get voted =>
      detail.recipes.where((r) => r.voteSummary.userVote != null).toList();

  HomeVoting copyWithDetail(MenuDetail d) =>
      HomeVoting(menus: menus, selected: selected, detail: d);

  @override
  List<Object?> get props => [menus, selected, detail];
}

/// User has voted on all recipes — waiting for partner or ready to finalize.
class HomeWaiting extends HomeState {
  final List<ActiveMenuSummary> menus;
  final ActiveMenuSummary selected;
  final MenuDetail detail;

  const HomeWaiting({
    required this.menus,
    required this.selected,
    required this.detail,
  });

  @override
  List<Object?> get props => [menus, selected, detail];
}

/// Menu is finalized.
class HomeFinalized extends HomeState {
  final List<ActiveMenuSummary> menus;
  final ActiveMenuSummary selected;
  final MenuDetail detail;

  const HomeFinalized({
    required this.menus,
    required this.selected,
    required this.detail,
  });

  @override
  List<Object?> get props => [menus, selected, detail];
}

class HomeError extends HomeState {
  final String message;
  const HomeError(this.message);
  @override
  List<Object?> get props => [message];
}
