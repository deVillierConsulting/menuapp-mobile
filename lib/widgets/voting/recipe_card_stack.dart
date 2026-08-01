import 'package:flutter/material.dart';
import '../../data/models/menu_detail.dart';
import '../../theme/app_colors.dart';
import '../cards/recipe_vote_card.dart';

/// Renders the card stack + progress dots for the voting screen.
///
/// Only the top card (index 0 of [pending]) is interactive. The card
/// directly below it is visible at a slight offset to create depth.
class RecipeCardStack extends StatelessWidget {
  final List<MenuRecipe> pending;
  final List<MenuRecipe> voted;
  final void Function(int menuRecipeId, VoteValue value) onVote;

  const RecipeCardStack({
    super.key,
    required this.pending,
    required this.voted,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Progress dots ─────────────────────────────────────────────────
        _ProgressDots(pending: pending, voted: voted),
        const SizedBox(height: 16),

        // ── Card stack ────────────────────────────────────────────────────
        Expanded(
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Peek card (one below top) — slightly scaled down, not draggable
              if (pending.length > 1)
                Positioned.fill(
                  child: Transform.translate(
                    offset: const Offset(0, 12),
                    child: Transform.scale(
                      scale: 0.94,
                      child: IgnorePointer(
                        child: RecipeVoteCard(
                          menuRecipe: pending[1],
                          votingEnabled: false,
                          onVote: (_) {},
                        ),
                      ),
                    ),
                  ),
                ),

              // Top card — the one the user interacts with
              if (pending.isNotEmpty)
                Positioned.fill(
                  child: RecipeVoteCard(
                    key: ValueKey(pending.first.menuRecipeId),
                    menuRecipe: pending.first,
                    onVote: (v) => onVote(pending.first.menuRecipeId, v),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Progress dots ─────────────────────────────────────────────────────────────

class _ProgressDots extends StatelessWidget {
  final List<MenuRecipe> pending;
  final List<MenuRecipe> voted;

  const _ProgressDots({required this.pending, required this.voted});

  @override
  Widget build(BuildContext context) {
    final all = [...voted, ...pending]; // voted first, then pending
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < all.length; i++) ...[
          if (i > 0) const SizedBox(width: 5),
          _Dot(recipe: all[i], isNext: i == voted.length),
        ],
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final MenuRecipe recipe;
  final bool isNext; // the card currently on top

  const _Dot({required this.recipe, required this.isNext});

  @override
  Widget build(BuildContext context) {
    final vote = recipe.voteSummary.userVote;

    if (isNext) {
      // Active dot: pill shape in accent orange
      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 16,
        height: 6,
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(3),
        ),
      );
    }

    if (vote == VoteValue.approve) {
      return _circle(AppColors.ok);
    }
    if (vote == VoteValue.veto) {
      return _circle(AppColors.danger);
    }
    // Unseen
    return _circle(AppColors.line);
  }

  Widget _circle(Color color) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      );
}
