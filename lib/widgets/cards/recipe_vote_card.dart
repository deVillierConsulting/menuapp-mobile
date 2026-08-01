import 'package:flutter/material.dart';
import '../../data/models/menu_detail.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

// How far the user must drag before we commit the vote on finger-lift.
const double _kThreshold = 100.0;
// Max drag distance used to clamp rotation and overlay opacity.
const double _kDragMax = 160.0;

/// Full-screen swipeable recipe card.
///
/// Fires [onVote] when the user swipes past the threshold or taps a verdict
/// button. The card itself does not animate itself off screen — the parent
/// [RecipeCardStack] removes it from the list immediately on vote.
class RecipeVoteCard extends StatefulWidget {
  final MenuRecipe menuRecipe;
  final bool votingEnabled;
  final void Function(VoteValue) onVote;

  const RecipeVoteCard({
    super.key,
    required this.menuRecipe,
    required this.onVote,
    this.votingEnabled = true,
  });

  @override
  State<RecipeVoteCard> createState() => _RecipeVoteCardState();
}

class _RecipeVoteCardState extends State<RecipeVoteCard>
    with SingleTickerProviderStateMixin {
  double _dragX = 0;

  void _onPanUpdate(DragUpdateDetails d) {
    if (!widget.votingEnabled) return;
    setState(() => _dragX += d.delta.dx);
  }

  void _onPanEnd(DragEndDetails _) {
    if (!widget.votingEnabled) return;
    if (_dragX.abs() >= _kThreshold) {
      widget.onVote(_dragX > 0 ? VoteValue.approve : VoteValue.veto);
    } else {
      setState(() => _dragX = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = (_dragX / _kDragMax).clamp(-1.0, 1.0);
    final angle = t * 0.12; // max ±~7 degrees
    final approveOpacity = t.clamp(0.0, 1.0);
    final vetoOpacity = (-t).clamp(0.0, 1.0);

    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Transform.translate(
        offset: Offset(_dragX, _dragX.abs() * 0.05),
        child: Transform.rotate(
          angle: angle,
          child: _CardFace(
            menuRecipe: widget.menuRecipe,
            approveOpacity: approveOpacity,
            vetoOpacity: vetoOpacity,
            votingEnabled: widget.votingEnabled,
            onVote: widget.onVote,
          ),
        ),
      ),
    );
  }
}

// ── Card face ─────────────────────────────────────────────────────────────────

class _CardFace extends StatelessWidget {
  final MenuRecipe menuRecipe;
  final double approveOpacity;
  final double vetoOpacity;
  final bool votingEnabled;
  final void Function(VoteValue) onVote;

  const _CardFace({
    required this.menuRecipe,
    required this.approveOpacity,
    required this.vetoOpacity,
    required this.votingEnabled,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    final recipe = menuRecipe.recipe;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Photo background ────────────────────────────────────────────
          _Photo(photoKey: recipe.photoKey),

          // ── Dark scrim so text is readable over any photo ───────────────
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.45, 1.0],
                colors: [Colors.transparent, Color(0xE0000000)],
              ),
            ),
          ),

          // ── Recipe info at the bottom ───────────────────────────────────
          Positioned(
            left: 20,
            right: 20,
            bottom: 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (recipe.cuisine != null)
                  _Chip(recipe.cuisine!.name),
                const SizedBox(height: 8),
                Text(
                  recipe.name,
                  style: AppTextStyles.h1.copyWith(
                    color: Colors.white,
                    fontSize: 26,
                    height: 1.2,
                  ),
                ),
                if (recipe.description != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    recipe.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
                if (recipe.calorieCount != null || recipe.proteinCount != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (recipe.calorieCount != null)
                        _StatPill('${recipe.calorieCount} cal'),
                      if (recipe.calorieCount != null &&
                          recipe.proteinCount != null)
                        const SizedBox(width: 6),
                      if (recipe.proteinCount != null)
                        _StatPill('${recipe.proteinCount}g protein'),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // ── Vote buttons at the very bottom ────────────────────────────
          if (votingEnabled)
            Positioned(
              left: 20,
              right: 20,
              bottom: 28,
              child: Row(
                children: [
                  _VoteButton(
                    icon: Icons.close_rounded,
                    color: AppColors.danger,
                    onTap: () => onVote(VoteValue.veto),
                  ),
                  const Spacer(),
                  _VoteButton(
                    icon: Icons.check_rounded,
                    color: AppColors.ok,
                    onTap: () => onVote(VoteValue.approve),
                  ),
                ],
              ),
            ),

          // ── Verdict overlays (fade in as user drags) ───────────────────
          if (approveOpacity > 0)
            Positioned(
              top: 48,
              left: 20,
              child: _VerdictBadge(
                label: 'YUM',
                color: AppColors.ok,
                opacity: approveOpacity,
                angle: -0.14,
              ),
            ),
          if (vetoOpacity > 0)
            Positioned(
              top: 48,
              right: 20,
              child: _VerdictBadge(
                label: 'NOPE',
                color: AppColors.danger,
                opacity: vetoOpacity,
                angle: 0.14,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _Photo extends StatelessWidget {
  final String? photoKey;
  const _Photo({this.photoKey});

  @override
  Widget build(BuildContext context) {
    if (photoKey == null) {
      return const ColoredBox(color: AppColors.line);
    }
    return Image.network(
      photoKey!,
      fit: BoxFit.cover,
      errorBuilder: (context, err, stack) => const ColoredBox(color: AppColors.line),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.caption.copyWith(
          color: Colors.white,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  const _StatPill(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: AppTextStyles.caption.copyWith(color: Colors.white)),
    );
  }
}

class _VoteButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _VoteButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 32),
      ),
    );
  }
}

class _VerdictBadge extends StatelessWidget {
  final String label;
  final Color color;
  final double opacity;
  final double angle;

  const _VerdictBadge({
    required this.label,
    required this.color,
    required this.opacity,
    required this.angle,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Transform.rotate(
        angle: angle,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
