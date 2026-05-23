import 'package:bcrypt/bcrypt.dart';

class PasswordHasher {
  const PasswordHasher();

  String hash(String plainPassword) {
    return BCrypt.hashpw(plainPassword, BCrypt.gensalt());
  }

  bool verify(String plainPassword, String passwordHash) {
    return BCrypt.checkpw(plainPassword, passwordHash);
  }
}
