import '../../../shared/models/user_role.dart';
import '../models/current_user.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated }

class AuthState {
  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  const AuthState.initial() : this(status: AuthStatus.initial);
  const AuthState.loading() : this(status: AuthStatus.loading);
  const AuthState.unauthenticated({String? errorMessage})
      : this(status: AuthStatus.unauthenticated, errorMessage: errorMessage);
  const AuthState.authenticated(CurrentUser user)
      : this(status: AuthStatus.authenticated, user: user);

  final AuthStatus status;
  final CurrentUser? user;
  final String? errorMessage;

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;
  UserRole? get activeRole => user?.role;
  UserRole? get role => user?.role;
}
