import 'dart:io';

import 'key_value_store.dart';

/// Prefijo de todas las claves locales que pertenecen al usuario con sesión.
/// Al cerrar sesión se borran para no filtrar datos a la siguiente cuenta.
const userDataPrefix = 'user.';

/// Borra los datos locales del usuario al cerrar sesión: las claves `user.` y el
/// directorio de archivos del usuario (p. ej. el índice de sus documentos para la IA).
class LocalDataCleaner {
  const LocalDataCleaner(this._store, [this._userFiles]);

  final KeyValueStore _store;
  final Future<Directory> Function()? _userFiles;

  Future<void> clearUserData() async {
    await _store.removeWithPrefix(userDataPrefix);
    final userFiles = _userFiles;
    if (userFiles == null) return;
    try {
      final dir = await userFiles();
      if (await dir.exists()) await dir.delete(recursive: true);
    } on Object {
      // Sin almacenamiento disponible (p. ej. en pruebas): no hay nada que borrar.
    }
  }
}
