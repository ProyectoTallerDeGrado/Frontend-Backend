import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'key_value_store.dart';
import 'local_data_cleaner.dart';
import 'token_storage.dart';
import 'user_files_directory.dart';

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => SecureTokenStorage(),
);

final keyValueStoreProvider = Provider<KeyValueStore>(
  (ref) => const SharedPrefsKeyValueStore(),
);

/// Dónde van los archivos del usuario con sesión (se borran al cerrar sesión).
final userFilesDirectoryProvider = Provider<Future<Directory> Function()>(
  (ref) => userFilesDirectory,
);

final localDataCleanerProvider = Provider<LocalDataCleaner>(
  (ref) => LocalDataCleaner(
    ref.watch(keyValueStoreProvider),
    ref.watch(userFilesDirectoryProvider),
  ),
);
