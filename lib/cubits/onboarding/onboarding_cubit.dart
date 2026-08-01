import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../data/guest_vote_store.dart';
import '../../data/menus_data_source.dart';
import '../../data/recipes_data_source.dart';
import 'onboarding_state.dart';

// After this many votes, show the ghost partner animation once.
const _kGhostTriggerCount = 3;

class OnboardingCubit extends Cubit<OnboardingState> {
  final RecipesDataSource _recipes;
  final MenusDataSource _menus;
  final AuthCubit _auth;

  // Tracks approve/veto per recipe for the migration payload.
  final Map<int, String> _voteMap = {};

  OnboardingCubit({
    required RecipesDataSource recipes,
    required MenusDataSource menus,
    required AuthCubit auth,
  })  : _recipes = recipes,
        _menus = menus,
        _auth = auth,
        super(const OnboardingSplash());

  // ── Flow progression ────────────────────────────────────────────────────────

  /// Called after the splash animation finishes (~1.5s).
  Future<void> splashDone() async {
    emit(const OnboardingTutorial(slideIndex: 0));
  }

  void nextSlide() {
    final current = state;
    if (current is! OnboardingTutorial) return;
    if (current.slideIndex < 2) {
      emit(OnboardingTutorial(slideIndex: current.slideIndex + 1));
    } else {
      _startVoting();
    }
  }

  void skipTutorial() => _startVoting();

  Future<void> _startVoting() async {
    emit(const OnboardingLoading());
    try {
      final pool = await _recipes.listOnboardingRecipes();
      // Restore any votes from a previous session (app backgrounded and back).
      final saved = await GuestVoteStore.loadVotes();
      for (final v in saved) {
        _voteMap[v.recipeId] = v.voteValue;
      }
      final votedCount = saved.length.clamp(0, pool.length);
      emit(OnboardingVoting(recipes: pool, votedCount: votedCount));
    } catch (e) {
      emit(OnboardingError(e.toString()));
    }
  }

  /// Called when the user swipes a card.
  Future<void> castVote(int recipeId, String voteValue) async {
    final current = state;
    if (current is! OnboardingVoting) return;

    _voteMap[recipeId] = voteValue;
    // Persist locally — survives backgrounding.
    await GuestVoteStore.addVote(
        GuestVote(recipeId: recipeId, voteValue: voteValue));

    final newCount = current.votedCount + 1;
    final allDone = newCount >= current.recipes.length;

    if (allDone) {
      final approveCount =
          _voteMap.values.where((v) => v == 'approve').length;
      emit(OnboardingSaveGate(approveCount: approveCount));
      return;
    }

    // Trigger ghost animation exactly once, after the 3rd vote.
    final triggerGhost = newCount == _kGhostTriggerCount;
    emit(OnboardingVoting(
      recipes: current.recipes,
      votedCount: newCount,
      showGhostNext: triggerGhost,
    ));
  }

  /// Called by the screen after it finishes playing the ghost animation.
  void ghostShown() {
    final current = state;
    if (current is! OnboardingVoting) return;
    emit(OnboardingVoting(
      recipes: current.recipes,
      votedCount: current.votedCount,
      showGhostNext: false,
    ));
  }

  // ── Save gate ───────────────────────────────────────────────────────────────

  /// User taps "Sign in to save" on the save gate.
  Future<void> signInWithApple() async {
    await _auth.signInWithApple();
    final authState = _auth.state;

    if (authState is AuthAuthenticated) {
      // Returning user — migrate votes immediately and go to paywall.
      await _migrateAndAdvance();
    } else if (authState is AuthNeedsProfile) {
      // Brand-new Apple user — they still need to create a profile.
      // Votes stay in SharedPreferences; the register flow will handle them.
      // The router redirect will send us to /register automatically.
    } else if (authState is AuthError) {
      // Surface the Supabase error on the save gate so we can diagnose.
      emit(OnboardingError(authState.message));
    }
    // Cancelled — stay on save gate (do nothing).
  }

  /// User skips sign-in from the save gate — skip migration, go to paywall.
  void skipSignIn() {
    emit(const OnboardingPaywall());
  }

  // ── Paywall ─────────────────────────────────────────────────────────────────

  /// Called when user starts a trial or completes purchase on the paywall.
  Future<void> startTrial() async {
    // TODO: wire up Stripe — for now just mark done and let router take over.
    await GuestVoteStore.markOnboardingComplete();
  }

  /// User skips the paywall.
  Future<void> skipPaywall() async {
    await GuestVoteStore.markOnboardingComplete();
  }

  // ── Guest session migration ─────────────────────────────────────────────────

  Future<void> _migrateAndAdvance() async {
    emit(const OnboardingMigrating());
    try {
      if (_voteMap.isNotEmpty) {
        final payload = _voteMap.entries
            .map((e) => {'recipe_id': e.key, 'vote_value': e.value})
            .toList();
        await _menus.migrateGuestSession(payload);
        await GuestVoteStore.clear();
      }
    } catch (_) {
      // Non-fatal — user is signed in, votes just won't be migrated.
    }
    emit(const OnboardingPaywall());
  }
}
