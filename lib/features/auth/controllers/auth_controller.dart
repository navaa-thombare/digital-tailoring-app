import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/services/app_providers.dart';
import '../../../domain/services/auth_service.dart';

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<AuthSession?>>((ref) {
  return AuthController(ref.watch(authServiceProvider));
});

class AuthController extends StateNotifier<AsyncValue<AuthSession?>> {
  AuthController(this._authService) : super(const AsyncValue.loading()) {
    restore();
  }

  final AuthService _authService;

  Future<void> restore() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_authService.restore);
  }

  Future<AuthSession> login(String identifier, String password) async {
    state = const AsyncValue.loading();
    final session = await _authService.login(identifier, password);
    state = AsyncValue.data(session);
    return session;
  }

  Future<void> changePassword(String newPassword) async {
    final session = state.value;
    if (session == null) return;
    await _authService.changePassword(session.userId, newPassword);
    await restore();
  }

  Future<void> logout() async {
    await _authService.logout();
    state = const AsyncValue.data(null);
  }
}
