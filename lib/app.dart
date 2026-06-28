import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'data/api_client.dart';
import 'data/groups_data_source.dart';
import 'data/menus_data_source.dart';
import 'data/recipes_data_source.dart';
import 'cubits/groups/groups_cubit.dart';
import 'router.dart';
import 'session/app_session.dart';
import 'theme/app_theme.dart';

class MenuApp extends StatelessWidget {
  const MenuApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ── Single source of truth for all shared objects ─────────────────────
    // Everything is created once here and passed down. No data source or
    // session object should be instantiated anywhere else in the app.
    final apiClient = ApiClient(baseUrl: 'http://192.168.1.105:8000');

    final groupsDataSource   = GroupsDataSource(apiClient);
    final menusDataSource    = MenusDataSource(apiClient);
    final recipesDataSource  = RecipesDataSource(apiClient);

    // AppSession is the single source of user identity.
    // Right now it defaults to Andrew (user_id=1).
    // When real auth lands, signIn() will populate this instead.
    final session = AppSession(userId: 1, userName: 'Andrew');

    final appRouter = buildRouter(
      session:          session,
      groupsDataSource: groupsDataSource,
      menusDataSource:  menusDataSource,
      recipesDataSource: recipesDataSource,
    );

    return BlocProvider(
      create: (_) => GroupsCubit(groupsDataSource)..loadGroups(),
      child: MaterialApp.router(
        title: 'MenuApp',
        theme: buildTheme(),
        routerConfig: appRouter,
      ),
    );
  }
}
