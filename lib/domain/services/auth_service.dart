import '../../core/errors/app_exception.dart';
import '../../core/security/password_hasher.dart';
import '../../core/security/secure_session_storage.dart';
import '../../data/repositories/auth_repository.dart';
import 'store_usage_service.dart';

class AuthSession {
  const AuthSession({
    required this.user,
    required this.sessionToken,
  });

  final Map<String, Object?> user;
  final String sessionToken;

  String get userId => user['id'] as String;
  bool get isSuperadmin => user['is_superadmin'] == 1;
  bool get forcePasswordChange => user['force_password_change'] == 1;
  String? get storeId => user['store_id'] as String?;
  String get fullName => user['full_name'] as String;
}

class AuthService {
  AuthService({
    AuthRepository? repository,
    PasswordHasher? passwordHasher,
    SecureSessionStorage? sessionStorage,
    StoreUsageService? storeUsageService,
  })  : _repository = repository ?? AuthRepository(),
        _passwordHasher = passwordHasher ?? const PasswordHasher(),
        _sessionStorage = sessionStorage ?? SecureSessionStorage(),
        _storeUsageService = storeUsageService ?? StoreUsageService();

  final AuthRepository _repository;
  final PasswordHasher _passwordHasher;
  final SecureSessionStorage _sessionStorage;
  final StoreUsageService _storeUsageService;

  Future<AuthSession> login(String identifier, String password) async {
    final user = await _repository.findUserByIdentifier(identifier.trim());
    if (user == null) {
      throw const AppException('Invalid username or password.');
    }
    if (user['is_active'] != 1) {
      throw const AppException('This user is inactive.');
    }
    final ok =
        _passwordHasher.verify(password, user['password_hash'] as String);
    if (!ok) {
      throw const AppException('Invalid username or password.');
    }

    await _storeUsageService.decrementUsageDaysIfNeeded();
    final token = await _repository.createSession(user['id'] as String);
    await _sessionStorage.saveSession(
        userId: user['id'] as String, token: token);
    final refreshed = await _repository.findUserById(user['id'] as String);
    return AuthSession(user: refreshed ?? user, sessionToken: token);
  }

  Future<AuthSession?> restore() async {
    final userId = await _sessionStorage.readUserId();
    final token = await _sessionStorage.readToken();
    if (userId == null || token == null) return null;
    final user = await _repository.findUserById(userId);
    if (user == null || user['is_active'] != 1) {
      await _sessionStorage.clear();
      return null;
    }
    return AuthSession(user: user, sessionToken: token);
  }

  Future<void> changePassword(String userId, String newPassword) async {
    if (newPassword.length < 10) {
      throw const AppException('Password must be at least 10 characters.');
    }
    final hash = _passwordHasher.hash(newPassword);
    await _repository.updatePassword(userId: userId, passwordHash: hash);
  }

  Future<void> logout() async {
    final token = await _sessionStorage.readToken();
    if (token != null) {
      await _repository.revokeSession(token);
    }
    await _sessionStorage.clear();
  }
}
