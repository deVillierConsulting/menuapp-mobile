import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../data/api_client.dart';
import 'app_nav_bar.dart';

/// The persistent scaffold that wraps all tab screens.
class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final ApiClient apiClient;
  final AuthCubit authCubit;

  const AppShell({
    super.key,
    required this.navigationShell,
    required this.apiClient,
    required this.authCubit,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (i) => navigationShell.goBranch(i),
      ),
    );
  }
}

/// Drives a directional slide between tab branches.
/// Each child is an isolated branch Navigator — no GlobalKey conflicts.
/// Inactive branches are kept alive via Offstage so state survives tab switches.
class AnimatedBranchContainer extends StatefulWidget {
  final int currentIndex;
  final List<Widget> children;
  const AnimatedBranchContainer({
    super.key,
    required this.currentIndex,
    required this.children,
  });

  @override
  State<AnimatedBranchContainer> createState() => _AnimatedBranchContainerState();
}

class _AnimatedBranchContainerState extends State<AnimatedBranchContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _curved;
  int _previousIndex = 0;
  bool _goingRight = true;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.currentIndex;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0, // Start complete so there's no animation on first build.
    );
    _curved = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void didUpdateWidget(AnimatedBranchContainer old) {
    super.didUpdateWidget(old);
    if (old.currentIndex != widget.currentIndex) {
      _goingRight = widget.currentIndex > old.currentIndex;
      _previousIndex = old.currentIndex;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curved,
      builder: (context, _) {
        final t = _curved.value;
        final animating = t < 1.0;

        return Stack(
          children: widget.children.asMap().entries.map((entry) {
            final i = entry.key;
            final child = entry.value;

            final isCurrent = i == widget.currentIndex;
            final isPrevious = i == _previousIndex && animating;

            if (!isCurrent && !isPrevious) {
              return Offstage(child: child);
            }

            final offset = isCurrent
                ? (_goingRight ? 1.0 : -1.0) * (1.0 - t)
                : (_goingRight ? -1.0 : 1.0) * t;

            return FractionalTranslation(
              translation: Offset(offset, 0),
              child: child,
            );
          }).toList(),
        );
      },
    );
  }
}
