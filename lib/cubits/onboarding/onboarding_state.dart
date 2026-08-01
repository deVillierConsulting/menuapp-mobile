import 'package:equatable/equatable.dart';
import '../../data/models/recipe.dart';

abstract class OnboardingState extends Equatable {
  const OnboardingState();
  @override
  List<Object?> get props => [];
}

/// Full-screen loading while we fetch the curated recipe pool.
class OnboardingLoading extends OnboardingState {
  const OnboardingLoading();
}

/// Animated splash — shown for ~1.5s, then auto-advances to tutorial.
class OnboardingSplash extends OnboardingState {
  const OnboardingSplash();
}

/// 3-slide value prop carousel ("pick", "match", "plan").
class OnboardingTutorial extends OnboardingState {
  final int slideIndex;
  const OnboardingTutorial({this.slideIndex = 0});
  @override
  List<Object?> get props => [slideIndex];
}

/// Live voting — the main swiping phase.
///
/// [recipes] is the full curated pool.
/// [votedCount] is how many have been voted on so far.
/// [showGhostNext] is true exactly once — after the 3rd vote, before the
/// ghost animation fires. The screen checks this flag, plays the animation,
/// then calls [cubit.ghostShown()] to clear it.
class OnboardingVoting extends OnboardingState {
  final List<Recipe> recipes;
  final int votedCount;
  final bool showGhostNext;

  const OnboardingVoting({
    required this.recipes,
    this.votedCount = 0,
    this.showGhostNext = false,
  });

  List<Recipe> get pending => recipes.sublist(votedCount);
  List<Recipe> get voted   => recipes.sublist(0, votedCount);

  @override
  List<Object?> get props => [recipes, votedCount, showGhostNext];
}

/// "Save your menu" interstitial — sunk-cost gate before sign-in prompt.
class OnboardingSaveGate extends OnboardingState {
  final int approveCount;
  const OnboardingSaveGate({required this.approveCount});
  @override
  List<Object?> get props => [approveCount];
}

/// Paywall — shown after sign-in completes and votes are migrated.
class OnboardingPaywall extends OnboardingState {
  const OnboardingPaywall();
}

/// Migrating guest votes to the server after SIWA.
class OnboardingMigrating extends OnboardingState {
  const OnboardingMigrating();
}

class OnboardingError extends OnboardingState {
  final String message;
  const OnboardingError(this.message);
  @override
  List<Object?> get props => [message];
}
