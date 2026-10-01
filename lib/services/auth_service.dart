class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();
  final Map<String, _LocalAccount> _accounts = {};
  _LocalAccount? _currentAccount;

  bool get isSignedIn => _currentAccount != null;

  void signOut() {
    _currentAccount = null;
  }

  void register({
    required String name,
    required String username,
    required String password,
    required int age,
  }) {
    final normalizedUsername = username.trim().toLowerCase();
    if (age < 16) {
      throw const AuthException('Kamu harus berusia minimal 16 tahun.');
    }
    if (_accounts.containsKey(normalizedUsername)) {
      throw const AuthException('Username sudah digunakan.');
    }

    final account = _LocalAccount(
      name: name.trim(),
      username: normalizedUsername,
      password: password,
      age: age,
    );
    _accounts[normalizedUsername] = account;
    _currentAccount = account;
  }

  void signIn({required String username, required String password}) {
    final account = _accounts[username.trim().toLowerCase()];
    if (account == null || account.password != password) {
      throw const AuthException('Username atau password salah.');
    }
    _currentAccount = account;
  }
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;
}

class _LocalAccount {
  const _LocalAccount({
    required this.name,
    required this.username,
    required this.password,
    required this.age,
  });

  final String name;
  final String username;
  final String password;
  final int age;
}
