import 'package:flutter_riverpod/misc.dart' show Override;

import '../../../core/network/providers.dart';
import '../presentation/controllers/needs_providers.dart';
import 'datasources/needs_remote_data_source.dart';
import 'repositories/needs_repository_impl.dart';

/// Implementación de `data` para el contrato de `domain` de la feature.
final List<Override> needsDataOverrides = [
  needsRepositoryProvider.overrideWith(
    (ref) => NeedsRepositoryImpl(NeedsRemoteDataSource(ref.watch(dioProvider))),
  ),
];
