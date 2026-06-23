import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/network/firebase_auth_service.dart';
import '../../../core/storage/secure_storage.dart';

// Repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// Auth state
class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user:      user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error:     error,
    );
  }

  bool get isAuthenticated => user != null;
}

// Auth notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthState()) {
    _loadCachedUser();
  }

  Future<void> _loadCachedUser() async {
    final user  = await _repository.getCachedUser();
    final token = await SecureStorage.getToken();

    if (user != null && token != null) {
      // Sign into Firebase with cached Laravel token
      await FirebaseAuthService.signInWithCustomToken(token);
      state = state.copyWith(user: user);
    }
  }

  Future<bool> login({
    required String phone,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await _repository.login(
        phone:    phone,
        password: password,
      );

      // Sign into Firebase after successful Laravel login
      final token = await SecureStorage.getToken();
      if (token != null) {
        await FirebaseAuthService.signInWithCustomToken(token);
      }

      state = state.copyWith(user: user, isLoading: false);
      return true;
    } on ServerException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } on UnauthorizedException {
      state = state.copyWith(
        isLoading: false,
        error:     'Invalid credentials.',
      );
      return false;
    } on NetworkException {
      state = state.copyWith(
        isLoading: false,
        error:     'No internet connection.',
      );
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Something went wrong.');
      return false;
    }
  }

  Future<void> refreshBalance() async {
    final updatedUser = await _repository.refreshUser();
    if (updatedUser != null) {
      state = state.copyWith(user: updatedUser);
    }
  }

  Future<bool> register({
    required String name,
    required String phone,
    required String password,
    required String passwordConfirmation,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await _repository.register(
        name:                 name,
        phone:                phone,
        password:             password,
        passwordConfirmation: passwordConfirmation,
      );

      // Sign into Firebase after successful registration
      final token = await SecureStorage.getToken();
      if (token != null) {
        await FirebaseAuthService.signInWithCustomToken(token);
      }

      state = state.copyWith(user: user, isLoading: false);
      return true;
    } on ServerException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } on NetworkException {
      state = state.copyWith(
        isLoading: false,
        error:     'No internet connection.',
      );
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Something went wrong.');
      return false;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    await FirebaseAuthService.signOut();
    state = const AuthState();
  }
}

// Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});