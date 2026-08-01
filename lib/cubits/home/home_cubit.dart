import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/groups_data_source.dart';
import '../../data/menus_data_source.dart';
import '../../data/models/active_menu_summary.dart';
import '../../data/models/menu.dart';
import '../../data/models/menu_detail.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final GroupsDataSource _groups;
  final MenusDataSource _menus;

  // Tracks which group the user last selected so we can restore on reload.
  int? _selectedGroupId;

  HomeCubit({
    required GroupsDataSource groups,
    required MenusDataSource menus,
  })  : _groups = groups,
        _menus = menus,
        super(const HomeLoading());

  // ── Public API ──────────────────────────────────────────────────────────────

  Future<void> load() async {
    emit(const HomeLoading());
    try {
      final groups = await _groups.getGroups();
      if (groups.isEmpty) {
        emit(const HomeNoGroup());
        return;
      }

      final activeMenus = await _menus.listActiveMenus();
      if (activeMenus.isEmpty) {
        emit(HomeNoMenu(menus: activeMenus));
        return;
      }

      // Restore previously selected group, or fall back to first in list.
      final selected = activeMenus.firstWhere(
        (m) => m.groupId == _selectedGroupId,
        orElse: () => activeMenus.first,
      );
      _selectedGroupId = selected.groupId;

      await _loadDetailFor(selected, activeMenus);
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  /// Switch to a different group's menu via the pill selector.
  Future<void> selectGroup(ActiveMenuSummary summary) async {
    final current = state;
    List<ActiveMenuSummary> menus;
    if (current is HomeVoting) {
      menus = current.menus;
    } else if (current is HomeWaiting) {
      menus = current.menus;
    } else if (current is HomeFinalized) {
      menus = current.menus;
    } else if (current is HomeNoMenu) {
      menus = current.menus;
    } else {
      return;
    }

    _selectedGroupId = summary.groupId;
    await _loadDetailFor(summary, menus);
  }

  /// Cast a vote and optimistically update the card stack.
  Future<void> castVote(int menuRecipeId, VoteValue value) async {
    final current = state;
    if (current is! HomeVoting) return;

    final optimistic = current.detail.copyWithUpdatedVote(menuRecipeId, value);
    _emitFromDetail(current.menus, current.selected, optimistic);

    try {
      await _menus.castVote(
        menuId: current.detail.menuId,
        menuRecipeId: menuRecipeId,
        value: value,
      );
    } catch (_) {
      // Roll back to the pre-vote state on failure.
      _emitFromDetail(current.menus, current.selected, current.detail);
    }
  }

  /// Finalize the menu — only callable from HomeWaiting.
  Future<void> finalizeMenu() async {
    final current = state;
    if (current is! HomeWaiting) return;
    try {
      await _menus.finalizeMenu(current.detail.menuId);
      await _menus.generateGroceryList(current.detail.menuId);
    } catch (_) {}
    // Reload to get the authoritative finalized state from the server.
    await _loadDetailFor(current.selected, current.menus);
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  Future<void> _loadDetailFor(
    ActiveMenuSummary selected,
    List<ActiveMenuSummary> menus,
  ) async {
    try {
      final detail = await _menus.getMenuDetail(selected.menuId);
      _emitFromDetail(menus, selected, detail);
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  void _emitFromDetail(
    List<ActiveMenuSummary> menus,
    ActiveMenuSummary selected,
    MenuDetail detail,
  ) {
    if (detail.status == MenuStatus.final_) {
      emit(HomeFinalized(menus: menus, selected: selected, detail: detail));
      return;
    }

    // A menu that exists but has no recipes yet is treated as "no menu" from
    // the home screen's perspective — we don't show an empty card stack.
    if (detail.recipes.isEmpty) {
      emit(HomeNoMenu(menus: menus, selected: selected));
      return;
    }

    final allVoted =
        detail.recipes.every((r) => r.voteSummary.userVote != null);

    if (allVoted) {
      emit(HomeWaiting(menus: menus, selected: selected, detail: detail));
    } else {
      emit(HomeVoting(menus: menus, selected: selected, detail: detail));
    }
  }
}
