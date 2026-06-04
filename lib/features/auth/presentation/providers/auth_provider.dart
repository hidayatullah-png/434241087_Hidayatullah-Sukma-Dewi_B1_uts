import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthState {
  final String name;
  final String role; // 'user' | 'helpdesk' | 'admin'
  final String email;
  final bool isLoggedIn;

  const AuthState({
    required this.name,
    required this.role,
    required this.email,
    required this.isLoggedIn,
  });

  factory AuthState.initial() => const AuthState(
    name: 'Guest',
    role: 'user',
    email: '',
    isLoggedIn: false,
  );
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    return AuthState.initial();
  }

  void setUser({
    required String name,
    required String role,
    required String email,
  }) {
    state = AuthState(name: name, role: role, email: email, isLoggedIn: true);
  }

  void logout() => state = AuthState.initial();
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
