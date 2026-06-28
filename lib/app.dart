import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'data/api_client.dart';
import 'data/groups_data_source.dart';
import 'data/menus_data_source.dart';
import 'data/recipes_data_source.dart';
import 'package:go_router/go_router.dart';
import 'cubits/groups/groups_cubit.dart';
import 'router.dart';
import 'session/app_session.dart';
import 'theme/app_theme.dart';

class MenuApp extends StatefulWidget {
  const MenuApp({super.key});

  @override
  State<MenuApp> createState() => _MenuAppState();
}

class _MenuAppState extends State<MenuApp> {
  // These are created once in initState and live for the entire app lifetime.
  // If they lived in build(), every rebuild would create new instances and
  // reset AppSession back to its default — killing the dev user switcher.
  late final ApiClient _apiClient;
  late final GroupsDataSource _groupsDataSource;
  late final MenusDataSource _menusDataSource;
  late final RecipesDataSource _recipesDataSource;
  late final AppSession _session;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient(baseUrl: 'http://192.168.1.105:8000');

    _groupsDataSource  = GroupsDataSource(_apiClient);
    _menusDataSource   = MenusDataSource(_apiClient);
    _recipesDataSource = RecipesDataSource(_apiClient);

    _session = AppSession(userId: 1, userName: 'Andrew');

    _router = buildRouter(
      session:           _session,
      groupsDataSource:  _groupsDataSource,
      menusDataSource:   _menusDataSource,
      recipesDataSource: _recipesDataSource,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GroupsCubit(_groupsDataSource)..loadGroups(),
      child: MaterialApp.router(
        title: 'MenuApp',
        theme: buildTheme(),
        routerConfig: _router,
      ),
    );
  }
}
