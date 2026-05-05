import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../../main.dart' show sharedPrefs;

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? error;

  AuthState({this.status = AuthStatus.initial, this.user, this.error});

  AuthState copyWith({AuthStatus? status, UserModel? user, String? error}) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Schedule auth check after the build completes
    Future.microtask(() => _checkAuth());
    return AuthState();
  }

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  Future<void> _checkAuth() async {
    // Use pre-initialized SharedPreferences synchronously
    final token = sharedPrefs.getString('access_token');
    if (token != null && token.isNotEmpty) {
      try {
        final user = await _repo.getProfile();
        state = AuthState(status: AuthStatus.authenticated, user: user);
      } catch (_) {
        // Token invalid or network error - go to login
        await sharedPrefs.remove('access_token');
        await sharedPrefs.remove('refresh_token');
        state = AuthState(status: AuthStatus.unauthenticated);
      }
    } else {
      state = AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      final data = await _repo.login(email, password);
      final user = UserModel.fromJson(data['user']);
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      String msg = 'Login failed. Please check your credentials.';
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused')) {
        msg = 'Cannot connect to server. Please try again later.';
      }
      state = AuthState(status: AuthStatus.error, error: msg);
    }
  }

  Future<void> register(String fullName, String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      final data = await _repo.register(fullName, email, password);
      final user = UserModel.fromJson(data['user']);
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      String msg = 'Registration failed. Please try again.';
      if (e.toString().contains('409') || e.toString().contains('Conflict')) {
        msg = 'Email already registered.';
      } else if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused')) {
        msg = 'Cannot connect to server. Please try again later.';
      }
      state = AuthState(status: AuthStatus.error, error: msg);
    }
  }

  Future<void> logout() async {
    await sharedPrefs.remove('access_token');
    await sharedPrefs.remove('refresh_token');
    state = AuthState(status: AuthStatus.unauthenticated);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
