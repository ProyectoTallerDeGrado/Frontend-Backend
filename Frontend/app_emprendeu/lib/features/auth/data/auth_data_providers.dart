import 'package:flutter_riverpod/misc.dart' show Override;

import '../../../core/network/providers.dart';
import '../../../core/storage/providers.dart';
import '../presentation/controllers/auth_providers.dart';
import 'datasources/auth_local_data_source.dart';
import 'datasources/auth_remote_data_source.dart';
import 'repositories/auth_repository_impl.dart';

/// Implementación de `data` para los contratos de `domain` de la feature.
/// La raíz de la app la registra en el `ProviderScope`.
final List<Override> authDataOverrides = [
  authRepositoryProvider.overrideWith(
    (ref) => AuthRepositoryImpl(
      AuthRemoteDataSource(ref.watch(dioProvider)),
      AuthLocalDataSource(ref.watch(tokenStorageProvider)),
    ),
  ),
];
