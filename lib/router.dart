import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'cubits/grocery_list/grocery_list_cubit.dart';
import 'cubits/group_detail/group_detail_cubit.dart';
import 'cubits/menu_detail/menu_detail_cubit.dart';
import 'cubits/recipe_detail/recipe_detail_cubit.dart';
import 'cubits/recipes/recipes_cubit.dart';
import 'cubits/shop/shop_cubit.dart';
import 'data/api_client.dart';
import 'data/auth_data_source.dart';
import 'data/groups_data_source.dart';
import 'data/menus_data_source.dart';
import 'data/recipes_data_source.dart';
import 'data/shop_data_source.dart';
import 'session/app_session.dart';
import 'widgets/nav/app_shell.dart';
import 'ui/groups/group_detail_screen.dart';
import 'ui/groups/groups_screen.dart';
import 'ui/menus/grocery_list_screen.dart';
import 'ui/menus/menu_detail_screen.dart';
import 'ui/recipes/recipe_detail_screen.dart';
import 'ui/recipes/recipes_screen.dart';
import 'ui/shop/shop_screen.dart';

/// Builds the app's router. All dependencies are passed in from app.dart —
/// nothing is instantiated here. This keeps the router a pure description
/// of navigation structure with no hidden state.
GoRouter buildRouter({
  required AppSession session,
  required ApiClient apiClient,
  required AuthDataSource authDataSource,
  required GroupsDataSource groupsDataSource,
  required MenusDataSource menusDataSource,
  required RecipesDataSource recipesDataSource,
  required ShopDataSource shopDataSource,
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
          AppShell(
            navigationShell: navigationShell,
            session: session,
            apiClient: apiClient,
            authDataSource: authDataSource,
          ),
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
              builder: (context, state) => GroupsScreen(
                dataSource: groupsDataSource,
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/recipes',
              builder: (context, state) => BlocProvider(
                create: (_) => RecipesCubit(dataSource: recipesDataSource),
                child: RecipesScreen(menusDataSource: menusDataSource),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/shop',
              builder: (context, state) => BlocProvider.value(
                value: context.read<ShopCubit>(),
                child: const ShopScreen(),
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
            groupsDataSource: groupsDataSource,
            session: session,
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
          ),
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
          ),
        );
      },
    ),
  ],
);

