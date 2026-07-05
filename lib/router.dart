import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'cubits/auth/auth_cubit.dart';
import 'cubits/grocery_list/grocery_list_cubit.dart';
import 'cubits/group_detail/group_detail_cubit.dart';
import 'cubits/menu_detail/menu_detail_cubit.dart';
import 'cubits/recipe_detail/recipe_detail_cubit.dart';
import 'cubits/recipes/recipes_cubit.dart';
import 'cubits/shop/shop_cubit.dart';
import 'data/api_client.dart';
import 'data/groups_data_source.dart';
import 'data/menus_data_source.dart';
import 'data/recipes_data_source.dart';
import 'data/shop_data_source.dart';
import 'widgets/nav/app_shell.dart';
import 'ui/auth/login_screen.dart';
import 'ui/auth/register_screen.dart';
import 'ui/groups/group_detail_screen.dart';
import 'ui/groups/groups_screen.dart';
import 'ui/menus/grocery_list_screen.dart';
import 'ui/menus/menu_detail_screen.dart';
import 'ui/recipes/recipe_detail_screen.dart';
import 'ui/recipes/recipes_screen.dart';
import 'ui/shop/shop_screen.dart';

GoRouter buildRouter({
  required AuthCubit authCubit,
  required ApiClient apiClient,
  required GroupsDataSource groupsDataSource,
  required MenusDataSource menusDataSource,
  required RecipesDataSource recipesDataSource,
  required ShopDataSource shopDataSource,
}) {
  return GoRouter(
    initialLocation: '/groups',
    // Redirect unauthenticated users to /login; send authenticated users
    // away from /login and /register once they have a profile.
    redirect: (context, state) {
      final authState = authCubit.state;
      final onAuthScreen = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (authState is AuthLoading) return null;
      if (authState is AuthUnauthenticated || authState is AuthError) {
        return onAuthScreen ? null : '/login';
      }
      if (authState is AuthNeedsProfile) {
        return state.matchedLocation == '/register' ? null : '/register';
      }
      // AuthAuthenticated — send away from auth screens.
      if (onAuthScreen) return '/groups';
      return null;
    },
    refreshListenable: _AuthStateListenable(authCubit),
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),

      StatefulShellRoute(
        builder: (context, state, navigationShell) => AppShell(
          navigationShell: navigationShell,
          apiClient: apiClient,
          authCubit: authCubit,
        ),
        navigatorContainerBuilder: (context, navigationShell, children) =>
            AnimatedBranchContainer(
          currentIndex: navigationShell.currentIndex,
          children: children,
        ),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/groups',
              builder: (context, state) =>
                  GroupsScreen(dataSource: groupsDataSource),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/recipes',
              builder: (context, state) => BlocProvider(
                create: (_) => RecipesCubit(dataSource: recipesDataSource),
                child: RecipesScreen(menusDataSource: menusDataSource),
              ),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/shop',
              builder: (context, state) => BlocProvider.value(
                value: context.read<ShopCubit>(),
                child: const ShopScreen(),
              ),
            ),
          ]),
        ],
      ),

      GoRoute(
        path: '/groups/:id',
        builder: (context, state) {
          final groupId = int.parse(state.pathParameters['id']!);
          return BlocProvider(
            create: (_) => GroupDetailCubit(
                dataSource: groupsDataSource, groupId: groupId),
            child: GroupDetailScreen(
              groupId: groupId,
              menusDataSource: menusDataSource,
              groupsDataSource: groupsDataSource,
              authCubit: authCubit,
            ),
          );
        },
      ),
      GoRoute(
        path: '/menus/:id',
        builder: (context, state) {
          final menuId = int.parse(state.pathParameters['id']!);
          return BlocProvider(
            create: (_) =>
                MenuDetailCubit(dataSource: menusDataSource, menuId: menuId),
            child: MenuDetailScreen(
              menuId: menuId,
              menusDataSource: menusDataSource,
              recipesDataSource: recipesDataSource,
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
                dataSource: menusDataSource, menuId: menuId),
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
                dataSource: recipesDataSource, recipeId: recipeId),
            child: RecipeDetailScreen(
              recipeId: recipeId,
              menusDataSource: menusDataSource,
            ),
          );
        },
      ),
    ],
  );
}

/// Makes GoRouter listen to AuthCubit state changes so redirects fire
/// automatically whenever auth state transitions.
class _AuthStateListenable extends ChangeNotifier {
  _AuthStateListenable(AuthCubit cubit) {
    cubit.stream.listen((_) => notifyListeners());
  }
}
