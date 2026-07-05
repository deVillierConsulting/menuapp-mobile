part of 'auth_cubit.dart';

sealed class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

/// Initial state while we check for a stored Supabase session.
final class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Supabase session exists and our backend confirmed the user row.
final class AuthAuthenticated extends AuthState {
  final int userId;
  final String userName;
  final String email;
  const AuthAuthenticated({
    required this.userId,
    required this.userName,
    required this.email,
  });
  @override
  List<Object?> get props => [userId, userName, email];
}

/// No session, or token expired — show the login screen.
final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Supabase auth succeeded but this user has no profile yet.
/// Show a name-entry screen, then POST /auth/register.
final class AuthNeedsProfile extends AuthState {
  const AuthNeedsProfile();
}

/// Something went wrong (network error, bad config, etc.).
final class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}
