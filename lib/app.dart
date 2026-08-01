import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'cubits/auth/auth_cubit.dart';
import 'cubits/groups/groups_cubit.dart';
import 'cubits/shop/shop_cubit.dart';
import 'package:go_router/go_router.dart';
import 'data/api_client.dart';
import 'data/auth_data_source.dart';
import 'data/guest_vote_store.dart';
import 'data/groups_data_source.dart';
import 'data/invite_data_source.dart';
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
  late final InviteDataSource _inviteDataSource;
  late final MenusDataSource _menusDataSource;
  late final RecipesDataSource _recipesDataSource;
  late final ShopDataSource _shopDataSource;
  late final AuthCubit _authCubit;
  late final GroupsCubit _groupsCubit;
  late final ShopCubit _shopCubit;

  // Resolved once at startup before the router is built.
  late final Future<bool> _onboardingDoneFuture;

  // Built once after _onboardingDoneFuture resolves; never recreated.
  GoRouter? _router;

  @override
  void initState() {
    super.initState();
    _apiClient         = ApiClient(baseUrl: 'http://192.168.1.105:8000');
    _authDataSource    = AuthDataSource(_apiClient);
    _groupsDataSource  = GroupsDataSource(_apiClient);
    _inviteDataSource  = InviteDataSource(_apiClient);
    _menusDataSource   = MenusDataSource(_apiClient);
    _recipesDataSource = RecipesDataSource(_apiClient);
    _shopDataSource    = ShopDataSource(_apiClient);

    _authCubit   = AuthCubit(_authDataSource, _apiClient);
    _groupsCubit = GroupsCubit(_groupsDataSource);
    _shopCubit   = ShopCubit(_shopDataSource);

    // Read both flags in parallel so startup delay is minimal.
    _onboardingDoneFuture = Future.wait([
      GuestVoteStore.isOnboardingComplete(),
      _authCubit.initialize().then((_) {
        if (_authCubit.state is AuthAuthenticated) {
          _groupsCubit.loadGroups();
          _shopCubit.load();
        }
      }),
    ]).then((results) => results[0] as bool);

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
    return FutureBuilder<bool>(
      future: _onboardingDoneFuture,
      builder: (context, snapshot) {
        // Keep showing the native splash until both futures resolve.
        if (!snapshot.hasData) {
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }

        // Build the router exactly once — GoRouter holds its own nav stack,
        // so recreating it on every rebuild would reset the user's location.
        _router ??= buildRouter(
          authCubit:          _authCubit,
          apiClient:          _apiClient,
          groupsDataSource:   _groupsDataSource,
          inviteDataSource:   _inviteDataSource,
          menusDataSource:    _menusDataSource,
          recipesDataSource:  _recipesDataSource,
          shopDataSource:     _shopDataSource,
          onboardingComplete: snapshot.data!,
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
            routerConfig: _router!,
          ),
        );
      },
    );
  }
}
