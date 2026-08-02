import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'cubits/auth/auth_cubit.dart';
import 'cubits/grocery_list/grocery_list_cubit.dart';
import 'cubits/invite/invite_cubit.dart';
import 'cubits/onboarding/onboarding_cubit.dart';
import 'cubits/group_detail/group_detail_cubit.dart';
import 'cubits/home/home_cubit.dart';
import 'cubits/menu_detail/menu_detail_cubit.dart';
import 'cubits/recipe_detail/recipe_detail_cubit.dart';
import 'cubits/recipes/recipes_cubit.dart';
import 'cubits/shop/shop_cubit.dart';
import 'data/api_client.dart';
import 'data/groups_data_source.dart';
import 'data/guest_vote_store.dart';
import 'data/invite_data_source.dart';
import 'data/menus_data_source.dart';
import 'data/recipes_data_source.dart';
import 'data/shop_data_source.dart';
import 'widgets/nav/app_shell.dart';
import 'ui/auth/login_screen.dart';
import 'ui/auth/register_screen.dart';
import 'ui/account/account_screen.dart';
import 'ui/groups/group_detail_screen.dart';
import 'ui/groups/join_group_screen.dart';
import 'ui/home/home_screen.dart';
import 'ui/onboarding/onboarding_screen.dart';
import 'ui/menus/grocery_list_screen.dart';
import 'ui/menus/menu_detail_screen.dart';
import 'ui/recipes/recipe_detail_screen.dart';
import 'ui/recipes/recipes_screen.dart';
import 'ui/shop/shop_screen.dart';

GoRouter buildRouter({
  required AuthCubit authCubit,
  required ApiClient apiClient,
  required GroupsDataSource groupsDataSource,
  required InviteDataSource inviteDataSource,
  required MenusDataSource menusDataSource,
  required RecipesDataSource recipesDataSource,
  required ShopDataSource shopDataSource,
  required bool onboardingComplete,
}) {
  return GoRouter(
    initialLocation: '/home',
    // Redirect unauthenticated users to /login; send authenticated users
    // away from /login and /register once they have a profile.
    redirect: (context, state) {
      final authState = authCubit.state;
      final loc = state.matchedLocation;
      final onAuthScreen = loc == '/login' || loc == '/register';
      final onOnboarding = loc == '/onboarding';
      final onJoin = loc.startsWith('/join/');

      if (authState is AuthLoading) return null;
      if (authState is AuthUnauthenticated || authState is AuthError) {
        if (onOnboarding) return null; // let onboarding run
        if (onAuthScreen) return null;
        if (onJoin) return null; // preview is public; join button gates on auth
        // New users go to onboarding; returning users go to login.
        // Also check the in-session flag — markOnboardingComplete() may have
        // been called this session even though onboardingComplete was false at startup.
        final doneNow = onboardingComplete || GuestVoteStore.completedThisSession;
        return doneNow ? '/login' : '/onboarding';
      }
      if (authState is AuthNeedsProfile) {
        return loc == '/register' ? null : '/register';
      }
      // AuthAuthenticated — send away from auth/onboarding screens.
      if (onAuthScreen || onOnboarding) return '/home';
      return null;
    },
    refreshListenable: _AuthStateListenable(authCubit),
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
      GoRoute(
        path: '/join/:token',
        builder: (context, state) {
          final token = state.pathParameters['token']!;
          return BlocProvider(
            create: (_) => InviteCubit(
                invites: inviteDataSource, token: token),
            child: const JoinGroupScreen(),
          );
        },
      ),

      GoRoute(
        path: '/onboarding',
        builder: (context, state) => BlocProvider(
          create: (_) => OnboardingCubit(
            recipes: recipesDataSource,
            menus: menusDataSource,
            auth: authCubit,
          ),
          child: const OnboardingScreen(),
        ),
      ),

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
              path: '/home',
              builder: (context, state) => BlocProvider(
                create: (_) => HomeCubit(
                  groups: groupsDataSource,
                  menus: menusDataSource,
                ),
                child: const HomeScreen(),
              ),
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
        path: '/account',
        builder: (context, state) => AccountScreen(
          authCubit: authCubit,
          groupsDataSource: groupsDataSource,
        ),
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
