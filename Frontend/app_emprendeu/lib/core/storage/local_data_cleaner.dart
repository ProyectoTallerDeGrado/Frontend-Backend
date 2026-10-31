import 'key_value_store.dart';

/// Prefijo de todas las claves locales que pertenecen al usuario con sesión.
/// Al cerrar sesión se borran para no filtrar datos a la siguiente cuenta.
const userDataPrefix = 'user.';

class LocalDataCleaner {
  const LocalDataCleaner(this._store);

  final KeyValueStore _store;

  Future<void> clearUserData() => _store.removeWithPrefix(userDataPrefix);
}
