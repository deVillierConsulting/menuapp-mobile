import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'cubits/auth/auth_cubit.dart';
import 'cubits/groups/groups_cubit.dart';
import 'cubits/shop/shop_cubit.dart';
import 'data/api_client.dart';
import 'data/auth_data_source.dart';
import 'data/groups_data_source.dart';
import 'data/menus_data_source.dart';
import 'data/recipes_data_source.dart';
import 'data/shop_data_source.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class MenuApp extends StatefulWidget {
  const MenuApp({super.key});

  @override
  State<MenuApp> createState() => _MenuAppState();
}

class _MenuAppState extends State<MenuApp> {
  late final ApiClient _apiClient;
  late final AuthDataSource _authDataSource;
  late final GroupsDataSource _groupsDataSource;
  late final MenusDataSource _menusDataSource;
  late final RecipesDataSource _recipesDataSource;
  late final ShopDataSource _shopDataSource;
  late final AuthCubit _authCubit;
  late final GroupsCubit _groupsCubit;
  late final ShopCubit _shopCubit;

  @override
  void initState() {
    super.initState();
    _apiClient         = ApiClient(baseUrl: 'http://192.168.1.105:8000');
    _authDataSource    = AuthDataSource(_apiClient);
    _groupsDataSource  = GroupsDataSource(_apiClient);
    _menusDataSource   = MenusDataSource(_apiClient);
    _recipesDataSource = RecipesDataSource(_apiClient);
    _shopDataSource    = ShopDataSource(_apiClient);

    _authCubit   = AuthCubit(_authDataSource, _apiClient);
    _groupsCubit = GroupsCubit(_groupsDataSource);
    _shopCubit   = ShopCubit(_shopDataSource);

    // Check for an existing Supabase session and validate it with the backend.
    // AuthCubit emits AuthAuthenticated → router redirects to /groups.
    // If no session, emits AuthUnauthenticated → router redirects to /login.
    _authCubit.initialize().then((_) {
      if (_authCubit.state is AuthAuthenticated) {
        _groupsCubit.loadGroups();
        _shopCubit.load();
      }
    });

    // Reload data whenever the user signs in (or switches accounts).
    _authCubit.stream.listen((state) {
      if (state is AuthAuthenticated) {
        _groupsCubit.loadGroups();
        _shopCubit.load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = buildRouter(
      authCubit:         _authCubit,
      apiClient:         _apiClient,
      groupsDataSource:  _groupsDataSource,
      menusDataSource:   _menusDataSource,
      recipesDataSource: _recipesDataSource,
      shopDataSource:    _shopDataSource,
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authCubit),
        BlocProvider.value(value: _groupsCubit),
        BlocProvider.value(value: _shopCubit),
      ],
      child: MaterialApp.router(
        title: 'MenuApp',
        theme: buildTheme(),
        routerConfig: router,
      ),
    );
  }
}
