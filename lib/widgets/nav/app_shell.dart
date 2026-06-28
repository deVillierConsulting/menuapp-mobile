import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../session/app_session.dart';
import 'app_nav_bar.dart';

/// The persistent scaffold that wraps all tab screens.
/// Owns the bottom nav bar and the dev user switcher.
class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final AppSession session;
  const AppShell({super.key, required this.navigationShell, required this.session});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: GestureDetector(
        // Long-press the nav bar to open the dev user switcher (debug builds only).
        onLongPress: kDebugMode
            ? () => _showUserSwitcher(context, session)
            : null,
        child: AppNavBar(
          currentIndex: navigationShell.currentIndex,
          onTap: (i) => navigationShell.goBranch(i),
        ),
      ),
    );
  }

  void _showUserSwitcher(BuildContext context, AppSession session) {
    const users = [
      (id: 1, name: 'Andrew'),
      (id: 2, name: 'Claire'),
      (id: 3, name: 'Matt'),
    ];

    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Icon(Icons.bug_report_outlined, size: 18),
                  SizedBox(width: 8),
                  Text('Dev user switcher',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            ...users.map((u) => ListTile(
                  title: Text(u.name),
                  subtitle: Text('user_id: ${u.id}'),
                  leading: CircleAvatar(child: Text(u.name[0])),
                  trailing: session.userId == u.id
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () {
                    session.switchUser(userId: u.id, userName: u.name);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Switched to ${u.name}')),
                    );
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
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
