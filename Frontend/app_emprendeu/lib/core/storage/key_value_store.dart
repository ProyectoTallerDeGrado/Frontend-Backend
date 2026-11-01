import 'package:shared_preferences/shared_preferences.dart';

/// Almacén local clave-valor (cola sin conexión, cachés pequeñas). Contrato mínimo
/// para sustituirlo en tests. El token NO va aquí: usa [TokenStorage] (almacén seguro).
abstract interface class KeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> remove(String key);

  /// Borra todas las claves que empiezan por [prefix].
  Future<void> removeWithPrefix(String prefix);
}

class SharedPrefsKeyValueStore implements KeyValueStore {
  const SharedPrefsKeyValueStore();

  @override
  Future<String?> read(String key) async =>
      (await SharedPreferences.getInstance()).getString(key);

  @override
  Future<void> write(String key, String value) async {
    await (await SharedPreferences.getInstance()).setString(key, value);
  }

  @override
  Future<void> remove(String key) async {
    await (await SharedPreferences.getInstance()).remove(key);
  }

  @override
  Future<void> removeWithPrefix(String prefix) async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getKeys().where((k) => k.startsWith(prefix))) {
      await prefs.remove(key);
    }
  }
}
