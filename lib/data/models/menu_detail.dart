import 'package:equatable/equatable.dart';
import 'menu.dart';
import 'recipe.dart';

enum VoteValue { yes, no, veto }

class VoteSummary extends Equatable {
  final int yes;
  final int no;
  final int veto;
  final VoteValue? userVote;

  const VoteSummary({
    this.yes = 0,
    this.no = 0,
    this.veto = 0,
    this.userVote,
  });

  factory VoteSummary.fromJson(Map<String, dynamic> json) => VoteSummary(
        yes: json['yes'] as int? ?? 0,
        no: json['no'] as int? ?? 0,
        veto: json['veto'] as int? ?? 0,
        userVote: _voteFromString(json['user_vote'] as String?),
      );

  static VoteValue? _voteFromString(String? s) => switch (s) {
        'yes' => VoteValue.yes,
        'no' => VoteValue.no,
        'veto' => VoteValue.veto,
        _ => null,
      };

  @override
  List<Object?> get props => [yes, no, veto, userVote];
}

class MenuRecipe extends Equatable {
  final int menuRecipeId;
  final Recipe recipe;
  final String addedAt;
  final VoteSummary voteSummary;

  const MenuRecipe({
    required this.menuRecipeId,
    required this.recipe,
    required this.addedAt,
    required this.voteSummary,
  });

  factory MenuRecipe.fromJson(Map<String, dynamic> json) => MenuRecipe(
        menuRecipeId: json['menu_recipe_id'] as int,
        recipe: Recipe.fromJson(json['recipe'] as Map<String, dynamic>),
        addedAt: json['added_at'] as String,
        voteSummary: VoteSummary.fromJson(
            json['vote_summary'] as Map<String, dynamic>? ?? {}),
      );

  int get totalVotes => voteSummary.yes + voteSummary.no + voteSummary.veto;
  bool get hasVeto => voteSummary.veto > 0;

  @override
  List<Object?> get props => [menuRecipeId, recipe, addedAt, voteSummary];
}

class MenuDetail extends Equatable {
  final int menuId;
  final int groupId;
  final String startDate;
  final String endDate;
  final MenuStatus status;
  final List<MenuRecipe> recipes;

  const MenuDetail({
    required this.menuId,
    required this.groupId,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.recipes,
  });

  factory MenuDetail.fromJson(Map<String, dynamic> json) => MenuDetail(
        menuId: json['menu_id'] as int,
        groupId: json['group_id'] as int,
        startDate: json['start_date'] as String,
        endDate: json['end_date'] as String,
        status: _statusFromString(json['status'] as String),
        recipes: (json['recipes'] as List<dynamic>)
            .map((e) => MenuRecipe.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  static MenuStatus _statusFromString(String s) => switch (s) {
        'active' => MenuStatus.active,
        'final' => MenuStatus.final_,
        _ => MenuStatus.draft,
      };

  // Returns a copy with one recipe's VoteSummary updated optimistically.
  MenuDetail copyWithUpdatedVote(int menuRecipeId, VoteValue newVote) {
    return MenuDetail(
      menuId: menuId,
      groupId: groupId,
      startDate: startDate,
      endDate: endDate,
      status: status,
      recipes: recipes.map((mr) {
        if (mr.menuRecipeId != menuRecipeId) return mr;
        final old = mr.voteSummary;
        final prev = old.userVote;
        // Decrement the old vote bucket, increment the new one.
        int yes = old.yes + (newVote == VoteValue.yes ? 1 : 0)
                            - (prev == VoteValue.yes ? 1 : 0);
        int no  = old.no  + (newVote == VoteValue.no  ? 1 : 0)
                            - (prev == VoteValue.no  ? 1 : 0);
        int veto = old.veto + (newVote == VoteValue.veto ? 1 : 0)
                              - (prev == VoteValue.veto ? 1 : 0);
        return MenuRecipe(
          menuRecipeId: mr.menuRecipeId,
          recipe: mr.recipe,
          addedAt: mr.addedAt,
          voteSummary: VoteSummary(
            yes: yes.clamp(0, 999),
            no: no.clamp(0, 999),
            veto: veto.clamp(0, 999),
            userVote: newVote,
          ),
        );
      }).toList(),
    );
  }

  // Days in the menu range, inclusive.
  int get totalDays {
    final start = DateTime.parse(startDate);
    final end = DateTime.parse(endDate);
    return end.difference(start).inDays + 1;
  }

  // How full the menu is — capped at 1.0.
  double get completeness => (recipes.length / totalDays).clamp(0.0, 1.0);

  @override
  List<Object?> get props => [menuId, groupId, startDate, endDate, status, recipes];
}
