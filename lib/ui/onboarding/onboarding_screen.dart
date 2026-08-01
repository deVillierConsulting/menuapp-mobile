import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../cubits/onboarding/onboarding_cubit.dart';
import '../../cubits/onboarding/onboarding_state.dart';
import '../../data/models/menu_detail.dart' as md;
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/voting/recipe_card_stack.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OnboardingCubit, OnboardingState>(
      // When voting migrates and the router reacts to auth state, we'll be
      // popped automatically. But mark onboarding done when we hit paywall so
      // the router redirect doesn't loop us back here on next cold start.
      listener: (context, state) {
        if (state is OnboardingPaywall || state is OnboardingMigrating) {
          // nothing to do — router handles nav after onboarding complete
        }
      },
      builder: (context, state) => switch (state) {
        OnboardingLoading()   => const _LoadingView(),
        OnboardingSplash()    => _SplashView(
            onDone: () => context.read<OnboardingCubit>().splashDone()),
        OnboardingTutorial()  => _TutorialView(state: state),
        OnboardingVoting()    => _VotingView(state: state),
        OnboardingSaveGate()  => _SaveGateView(state: state),
        OnboardingMigrating() => const _MigratingView(),
        OnboardingPaywall()   => _PaywallView(onDone: () => context.go('/home')),
        OnboardingError()     => _ErrorView(message: state.message),
        _                     => const SizedBox.shrink(),
      },
    );
  }
}

// ── Loading ───────────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

// ── Splash ────────────────────────────────────────────────────────────────────

class _SplashView extends StatefulWidget {
  final VoidCallback onDone;
  const _SplashView({required this.onDone});

  @override
  State<_SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<_SplashView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 1600), widget.onDone);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: FadeTransition(
        opacity: _fade,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🍽️', style: TextStyle(fontSize: 72)),
              const SizedBox(height: 20),
              Text(
                'MenuApp',
                style: AppTextStyles.h1.copyWith(
                  color: Colors.white,
                  fontSize: 32,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Meals you both love.',
                style: AppTextStyles.body.copyWith(
                    color: Colors.white.withValues(alpha: 0.6)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tutorial carousel ────────────────────────────────────────────────────────

const _slides = [
  (
    emoji: '👆',
    headline: 'Swipe to vote',
    body:
        'Swipe right on recipes you love, left on ones you\'d rather skip.',
  ),
  (
    emoji: '🤝',
    headline: 'Match with your partner',
    body:
        'When you both approve a recipe, it lands on your weekly menu.',
  ),
  (
    emoji: '🛒',
    headline: 'Shop together',
    body:
        'Your grocery list builds itself from everything you both agreed on.',
  ),
];

class _TutorialView extends StatelessWidget {
  final OnboardingTutorial state;
  const _TutorialView({required this.state});

  @override
  Widget build(BuildContext context) {
    final slide = _slides[state.slideIndex];
    final cubit = context.read<OnboardingCubit>();
    final isLast = state.slideIndex == 2;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
          child: Column(
            children: [
              // Skip link — top right
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: cubit.skipTutorial,
                  child: Text('Skip',
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.ink3)),
                ),
              ),
              const Spacer(),
              Text(slide.emoji, style: const TextStyle(fontSize: 72)),
              const SizedBox(height: 28),
              Text(slide.headline,
                  style: AppTextStyles.h1.copyWith(fontSize: 26),
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(slide.body,
                  style: AppTextStyles.body, textAlign: TextAlign.center),
              const Spacer(),
              // Progress dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == state.slideIndex ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == state.slideIndex
                          ? AppColors.accent
                          : AppColors.line,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: cubit.nextSlide,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  minimumSize: const Size.fromHeight(52),
                ),
                child: Text(isLast ? "Let's go" : 'Next',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Voting ────────────────────────────────────────────────────────────────────

class _VotingView extends StatefulWidget {
  final OnboardingVoting state;
  const _VotingView({required this.state});

  @override
  State<_VotingView> createState() => _VotingViewState();
}

class _VotingViewState extends State<_VotingView> {
  bool _ghostPlayed = false;

  @override
  void didUpdateWidget(_VotingView old) {
    super.didUpdateWidget(old);
    // Fire the ghost animation once when showGhostNext flips to true.
    if (widget.state.showGhostNext && !_ghostPlayed) {
      _ghostPlayed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showGhostAnimation(context);
      });
    }
  }

  Future<void> _showGhostAnimation(BuildContext ctx) async {
    await showDialog<void>(
      context: ctx,
      barrierDismissible: false,
      builder: (dialogCtx) => const _GhostVoteOverlay(),
    );
    if (mounted) {
      // ignore: use_build_context_synchronously
      ctx.read<OnboardingCubit>().ghostShown();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final cubit = context.read<OnboardingCubit>();

    // Wrap in a fake MenuRecipe shell so RecipeCardStack can accept Recipe.
    final pendingMr = state.pending
        .map((r) => _RecipeFacade(recipe: r))
        .toList();
    final votedMr = state.voted
        .map((r) => _RecipeFacade(recipe: r))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  Text(
                    'What sounds good?',
                    style: AppTextStyles.h1
                        .copyWith(color: Colors.white, fontSize: 18),
                  ),
                  const Spacer(),
                  Text(
                    '${state.votedCount}/${state.recipes.length}',
                    style: AppTextStyles.caption
                        .copyWith(color: Colors.white54),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _OnboardingCardStack(
                  pending: pendingMr,
                  voted: votedMr,
                  onVote: (menuRecipeId, value) => cubit.castVote(
                    menuRecipeId,
                    value == md.VoteValue.approve ? 'approve' : 'veto',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Fake MenuRecipe shell ────────────────────────────────────────────────────
// RecipeCardStack and RecipeVoteCard expect MenuRecipe objects. During
// onboarding we only have Recipe objects (no menu exists yet), so we wrap
// each Recipe in a minimal shim that satisfies the interface.

class _RecipeFacade extends md.MenuRecipe {
  _RecipeFacade({required super.recipe})
      : super(
          menuRecipeId: recipe.recipeId,
          addedAt: '',
          voteSummary: const md.VoteSummary(),
        );
}

// Passes Recipe-backed facades to RecipeCardStack unchanged.
class _OnboardingCardStack extends RecipeCardStack {
  const _OnboardingCardStack({
    required super.pending,
    required super.voted,
    required super.onVote,
  });
}

// ── Ghost vote overlay ────────────────────────────────────────────────────────

class _GhostVoteOverlay extends StatefulWidget {
  const _GhostVoteOverlay();

  @override
  State<_GhostVoteOverlay> createState() => _GhostVoteOverlayState();
}

class _GhostVoteOverlayState extends State<_GhostVoteOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _slide;
  late final AnimationController _card;
  late final Animation<Offset> _cardOffset;
  late final Animation<double> _calloutFade;

  @override
  void initState() {
    super.initState();
    // Card slides off to the right (ghost approve) over 600ms.
    _card = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _cardOffset = Tween<Offset>(begin: Offset.zero, end: const Offset(1.5, 0))
        .animate(CurvedAnimation(parent: _card, curve: Curves.easeIn));

    // Callout slides up after the card exits.
    _slide = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _calloutFade = CurvedAnimation(parent: _slide, curve: Curves.easeOut);

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 400));
    await _card.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    await _slide.forward();
    await Future.delayed(const Duration(milliseconds: 1800));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _card.dispose();
    _slide.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black87,
      child: SafeArea(
        child: Stack(
          children: [
            // Ghost card sliding right with green tint
            Positioned.fill(
              child: SlideTransition(
                position: _cardOffset,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(20, 60, 20, 120),
                  decoration: BoxDecoration(
                    color: AppColors.ok.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.ok.withValues(alpha: 0.5), width: 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Ghost avatar
                      Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          color: AppColors.ok,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text('C',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text('Your partner approved this!',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),

            // "Invite to vote together" callout
            Positioned(
              bottom: 32,
              left: 24,
              right: 24,
              child: FadeTransition(
                opacity: _calloutFade,
                child: SlideTransition(
                  position: Tween<Offset>(
                          begin: const Offset(0, 0.3), end: Offset.zero)
                      .animate(_calloutFade),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Text('👥', style: TextStyle(fontSize: 28)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Vote together',
                                  style: AppTextStyles.bodyMedium),
                              Text('Invite your partner to vote on the same recipes.',
                                  style: AppTextStyles.caption),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Save gate ─────────────────────────────────────────────────────────────────

class _SaveGateView extends StatelessWidget {
  final OnboardingSaveGate state;
  const _SaveGateView({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 24, 32, 40),
          child: Column(
            children: [
              const Spacer(),
              const Text('🔒', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 24),
              Text(
                'Save your menu',
                style: AppTextStyles.h1.copyWith(fontSize: 28),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'You approved ${state.approveCount} recipe${state.approveCount == 1 ? '' : 's'}. '
                'Sign in to save your picks and invite your partner to vote.',
                style: AppTextStyles.body,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              FilledButton(
                onPressed: cubit.signInWithApple,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.ink,
                  minimumSize: const Size.fromHeight(52),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.apple, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('Sign in with Apple',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: cubit.skipSignIn,
                child: Text('Maybe later',
                    style: AppTextStyles.body.copyWith(color: AppColors.ink3)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Migrating ─────────────────────────────────────────────────────────────────

class _MigratingView extends StatelessWidget {
  const _MigratingView();
  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Saving your picks…'),
            ],
          ),
        ),
      );
}

// ── Paywall ───────────────────────────────────────────────────────────────────

class _PaywallView extends StatelessWidget {
  final VoidCallback onDone;
  const _PaywallView({required this.onDone});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 24, 32, 40),
          child: Column(
            children: [
              const Spacer(),
              const Text('✨', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 24),
              Text(
                'Start your free trial',
                style: AppTextStyles.h1.copyWith(fontSize: 28),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                '7 days free, then \$4.99/month. Cancel anytime.',
                style: AppTextStyles.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Feature list
              for (final feature in [
                '✓  Unlimited weekly menus',
                '✓  Invite your partner or family',
                '✓  Auto grocery list',
                '✓  Recipe library with 200+ meals',
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(feature, style: AppTextStyles.bodyMedium),
                  ),
                ),
              const Spacer(),
              FilledButton(
                onPressed: () async {
                  await cubit.startTrial();
                  onDone();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  minimumSize: const Size.fromHeight(52),
                ),
                child: const Text('Start free trial',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () async {
                  await cubit.skipPaywall();
                  onDone();
                },
                child: Text('Not now',
                    style: AppTextStyles.body.copyWith(color: AppColors.ink3)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Error ─────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Something went wrong', style: AppTextStyles.bodyMedium),
              const SizedBox(height: 8),
              Text(message,
                  style: AppTextStyles.caption.copyWith(color: AppColors.ink3),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () =>
                    context.read<OnboardingCubit>().skipTutorial(),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
