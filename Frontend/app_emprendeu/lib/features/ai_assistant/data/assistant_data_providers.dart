import 'package:flutter_riverpod/misc.dart' show Override;

import '../../../core/network/providers.dart';
import '../presentation/controllers/assistant_providers.dart';
import 'datasources/assistant_remote_data_source.dart';
import 'repositories/assistant_repository_impl.dart';

final List<Override> assistantDataOverrides = [
  assistantRepositoryProvider.overrideWith(
    (ref) => AssistantRepositoryImpl(
      AssistantRemoteDataSource(ref.watch(dioProvider)),
    ),
  ),
];
