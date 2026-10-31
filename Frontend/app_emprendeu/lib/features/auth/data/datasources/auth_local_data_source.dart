import '../../../../core/storage/token_storage.dart';

/// Persistencia local del token de acceso.
class AuthLocalDataSource {
  const AuthLocalDataSource(this._storage);

  final TokenStorage _storage;

  Future<String?> readToken() => _storage.read();
  Future<void> saveToken(String token) => _storage.write(token);
  Future<void> clearToken() => _storage.clear();
}
