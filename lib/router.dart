import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'ui/groups/groups_screen.dart';
import 'ui/recipes/recipes_screen.dart';
import 'widgets/nav/app_nav_bar.dart';

// The shell wraps both tabs in a persistent bottom nav bar.
// Screens inside a ShellRoute share the same nav bar — it doesn't
// disappear and reappear as you switch tabs.
final router = GoRouter(
  initialLocation: '/groups',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/groups',
          builder: (context, state) => const GroupsScreen(),
        ),
        GoRoute(
          path: '/recipes',
          builder: (context, state) => const RecipesScreen(),
        ),
      ],
    ),
  ],
);

// AppShell owns the BottomNavigationBar and swaps content via `child`.
// It doesn't know what's inside each tab — that's the router's job.
class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/recipes')) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: AppNavBar(
        currentIndex: _selectedIndex(context),
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/groups');
            case 1:
              context.go('/recipes');
          }
        },
      ),
    );
  }
}
