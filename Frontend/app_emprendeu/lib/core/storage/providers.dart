import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'key_value_store.dart';
import 'local_data_cleaner.dart';
import 'token_storage.dart';

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => SecureTokenStorage(),
);

final keyValueStoreProvider = Provider<KeyValueStore>(
  (ref) => const SharedPrefsKeyValueStore(),
);

final localDataCleanerProvider = Provider<LocalDataCleaner>(
  (ref) => LocalDataCleaner(ref.watch(keyValueStoreProvider)),
);
