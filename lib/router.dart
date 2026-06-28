import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'cubits/grocery_list/grocery_list_cubit.dart';
import 'cubits/group_detail/group_detail_cubit.dart';
import 'cubits/menu_detail/menu_detail_cubit.dart';
import 'cubits/recipe_detail/recipe_detail_cubit.dart';
import 'cubits/recipes/recipes_cubit.dart';
import 'data/groups_data_source.dart';
import 'data/menus_data_source.dart';
import 'data/recipes_data_source.dart';
import 'session/app_session.dart';
import 'ui/groups/group_detail_screen.dart';
import 'ui/groups/groups_screen.dart';
import 'ui/menus/grocery_list_screen.dart';
import 'ui/menus/menu_detail_screen.dart';
import 'ui/recipes/recipe_detail_screen.dart';
import 'ui/recipes/recipes_screen.dart';
import 'widgets/nav/app_nav_bar.dart';

/// Builds the app's router. All dependencies are passed in from app.dart —
/// nothing is instantiated here. This keeps the router a pure description
/// of navigation structure with no hidden state.
GoRouter buildRouter({
  required AppSession session,
  required GroupsDataSource groupsDataSource,
  required MenusDataSource menusDataSource,
  required RecipesDataSource recipesDataSource,
}) =>
    GoRouter(
  initialLocation: '/groups',
  routes: [
    // StatefulShellRoute keeps each branch's Navigator alive independently,
    // which means no shared GlobalKeys — the root cause of our AnimatedSwitcher crash.
    // navigatorContainerBuilder gives us the branch widgets as a List<Widget>
    // so we can drive our own transition between them.
    StatefulShellRoute(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell, session: session),
      navigatorContainerBuilder: (context, navigationShell, children) =>
          AnimatedBranchContainer(
            currentIndex: navigationShell.currentIndex,
            children: children,
          ),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/groups',
              builder: (context, state) => const GroupsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/recipes',
              builder: (context, state) => BlocProvider(
                create: (_) => RecipesCubit(dataSource: recipesDataSource),
                child: RecipesScreen(menusDataSource: menusDataSource, session: session),
              ),
            ),
          ],
        ),
      ],
    ),
    // Detail routes live outside the shell — no bottom nav, full iOS slide transition.
    GoRoute(
      path: '/groups/:id',
      builder: (context, state) {
        final groupId = int.parse(state.pathParameters['id']!);
        return BlocProvider(
          create: (_) => GroupDetailCubit(
            dataSource: groupsDataSource,
            groupId: groupId,
          ),
          child: GroupDetailScreen(
            groupId: groupId,
            menusDataSource: menusDataSource,
          ),
        );
      },
    ),
    GoRoute(
      path: '/menus/:id',
      builder: (context, state) {
        final menuId = int.parse(state.pathParameters['id']!);
        return BlocProvider(
          create: (_) => MenuDetailCubit(
            dataSource: menusDataSource,
            menuId: menuId,
            session: session,
          ),
          child: MenuDetailScreen(
            menuId: menuId,
            menusDataSource: menusDataSource,
            recipesDataSource: recipesDataSource,
            session: session,
          ),
        );
      },
    ),
    GoRoute(
      path: '/menus/:id/grocery-list',
      builder: (context, state) {
        final menuId = int.parse(state.pathParameters['id']!);
        return BlocProvider(
          create: (_) => GroceryListCubit(
            dataSource: menusDataSource,
            menuId: menuId,
          ),
          child: GroceryListScreen(menuId: menuId),
        );
      },
    ),
    GoRoute(
      path: '/recipes/:id',
      builder: (context, state) {
        final recipeId = int.parse(state.pathParameters['id']!);
        return BlocProvider(
          create: (_) => RecipeDetailCubit(
            dataSource: recipesDataSource,
            recipeId: recipeId,
          ),
          child: RecipeDetailScreen(
            recipeId: recipeId,
            menusDataSource: menusDataSource,
            session: session,
          ),
        );
      },
    ),
  ],
);

// AppShell is stateless — it only owns the Scaffold and nav bar.
// Direction tracking lives in AnimatedBranchContainer where it belongs.
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
    // Seeded dev users — replace with real user list once auth lands.
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

// Drives a directional slide between branches.
// Each child is an isolated branch Navigator — no GlobalKey conflicts.
// Inactive branches are kept alive (Offstage) so state is preserved across tab switches.
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
              // Keep the branch mounted but invisible so its state survives.
              return Offstage(child: child);
            }

            // Entering branch slides in from the direction of travel.
            // Leaving branch slides out in the opposite direction.
            // Both move simultaneously for a clean page-peel feel.
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
