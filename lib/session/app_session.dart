import 'package:flutter/foundation.dart';

/// Holds the identity of the currently active user.
///
/// Right now this is a simple dev-switchable user ID.
/// When real auth lands, this class absorbs the auth token and user profile
/// without changing any of its callers — they all just keep reading userId.
class AppSession extends ChangeNotifier {
  int _userId;
  String _userName;

  AppSession({required int userId, required String userName})
      : _userId = userId,
        _userName = userName;

  int get userId => _userId;
  String get userName => _userName;

  /// Dev-only: switch the active user without a real auth flow.
  /// Called by the debug user switcher. Notifies all listeners so cubits
  /// that hold a reference can react if needed.
  void switchUser({required int userId, required String userName}) {
    assert(kDebugMode, 'switchUser is only available in debug builds');
    _userId = userId;
    _userName = userName;
    notifyListeners();
  }

  // ── Future auth surface ───────────────────────────────────────────────────
  //
  // When real auth arrives, these fields get added here:
  //
  //   String? _authToken;
  //   DateTime? _tokenExpiry;
  //
  //   Future<void> signIn(String email, String password) async {
  //     final result = await _authService.signIn(email, password);
  //     _authToken = result.token;
  //     _userId    = result.user.id;
  //     _userName  = result.user.name;
  //     notifyListeners();
  //   }
  //
  //   Future<void> signOut() async { ... }
  //
  //   bool get isAuthenticated => _authToken != null && !_isExpired;
  //
  // Nothing downstream changes — cubits still just read session.userId.
}
