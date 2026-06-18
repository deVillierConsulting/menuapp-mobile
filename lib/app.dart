import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'data/api_client.dart';
import 'data/groups_data_source.dart';
import 'repositories/group_repository.dart';
import 'cubits/groups/groups_cubit.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class MenuApp extends StatelessWidget {
  const MenuApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient(baseUrl: 'http://192.168.1.105:8000');
    final groupRepository = GroupRepository(GroupsDataSource(apiClient));

    // MaterialApp.router hands navigation control to go_router.
    // Instead of a `home:` screen, we pass `routerConfig:` — the router
    // decides what to show based on the current path.
    return BlocProvider(
      create: (_) => GroupsCubit(groupRepository)..loadGroups(),
      child: MaterialApp.router(
        title: 'MenuApp',
        theme: buildTheme(),
        routerConfig: router,
      ),
    );
  }
}
