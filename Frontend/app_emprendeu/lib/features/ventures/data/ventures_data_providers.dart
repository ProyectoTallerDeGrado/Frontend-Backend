import 'package:flutter_riverpod/misc.dart' show Override;

import '../../../core/network/providers.dart';
import '../presentation/controllers/ventures_providers.dart';
import 'datasources/ventures_remote_data_source.dart';
import 'repositories/ventures_repository_impl.dart';

/// Implementación de `data` para los contratos de `domain` de la feature.
final List<Override> venturesDataOverrides = [
  venturesRepositoryProvider.overrideWith(
    (ref) => VenturesRepositoryImpl(
      VenturesRemoteDataSource(ref.watch(dioProvider)),
    ),
  ),
];
