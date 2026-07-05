import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/auth_data_source.dart';
import '../../data/api_client.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthDataSource _dataSource;
  final ApiClient _apiClient;

  AuthCubit(this._dataSource, this._apiClient) : super(const AuthLoading());

  /// Called on app startup. Checks for an existing Supabase session, validates
  /// it with the backend, then subscribes to token refreshes so ApiClient always
  /// has a current access token without requiring a re-login.
  Future<void> initialize() async {
    // Keep ApiClient in sync whenever Supabase silently refreshes the token.
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      debugPrint('[AuthCubit] onAuthStateChange: event=${data.event}, session=${data.session == null ? "null" : "present"}');
      final session = data.session;
      if (session != null) {
        _apiClient.setToken(session.accessToken);
      } else {
        _apiClient.clearToken();
      }
    });

    final session = Supabase.instance.client.auth.currentSession;
    debugPrint('[AuthCubit] initialize: session=${session == null ? "null" : "present"}, provider=${session?.user.appMetadata['provider']}');
    if (session == null) {
      emit(const AuthUnauthenticated());
      return;
    }
    await _applySession(session);
  }

  /// Send an OTP to the given email. The user then calls verifyOtp().
  Future<void> sendOtp(String email) async {
    try {
      await Supabase.instance.client.auth.signInWithOtp(email: email);
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    }
  }

  /// Verify the OTP code the user received by email.
  Future<void> verifyOtp(String email, String token) async {
    try {
      final response = await Supabase.instance.client.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.email,
      );
      if (response.session != null) {
        await _applySession(response.session!);
      } else {
        emit(const AuthError('Verification failed — please try again.'));
      }
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    }
  }

  /// Sign in with Apple — native sheet, no browser redirect.
  Future<void> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final idToken = credential.identityToken;
      if (idToken == null) {
        emit(const AuthError('Sign in with Apple did not return a token.'));
        return;
      }
      final response = await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
      );
      if (response.session != null) {
        await _applySession(response.session!);
      } else {
        emit(const AuthError('Sign in with Apple failed — please try again.'));
      }
    } on SignInWithAppleAuthorizationException catch (e) {
      // User cancelled — not an error worth showing.
      if (e.code != AuthorizationErrorCode.canceled) {
        emit(AuthError(e.message));
      }
    } on AuthException catch (e) {
      emit(AuthError(e.message));
    }
  }

  /// Create a profile for a first-time user (AuthNeedsProfile state).
  Future<void> register(String name) async {
    try {
      final me = await _dataSource.register(name);
      emit(AuthAuthenticated(
        userId: me.userId,
        userName: me.userName,
        email: me.email,
      ));
    } on ApiException catch (e) {
      emit(AuthError(e.message));
    }
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
    _apiClient.clearToken();
    emit(const AuthUnauthenticated());
  }

  Future<void> _applySession(Session session) async {
    debugPrint('[AuthCubit] _applySession: token prefix=${session.accessToken.substring(0, 20)}...');
    _apiClient.setToken(session.accessToken);
    try {
      final me = await _dataSource.me();
      emit(AuthAuthenticated(
        userId: me.userId,
        userName: me.userName,
        email: me.email,
      ));
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        emit(const AuthNeedsProfile());
      } else {
        emit(AuthError(e.message));
      }
    }
  }
}
