import 'package:flutter_riverpod/misc.dart' show Override;

import '../../../core/network/providers.dart';
import '../../../core/storage/providers.dart';
import '../presentation/controllers/mentoring_providers.dart';
import 'datasources/mentoring_local_data_source.dart';
import 'datasources/mentoring_remote_data_source.dart';
import 'repositories/mentoring_repository_impl.dart';

final List<Override> mentoringDataOverrides = [
  mentoringRepositoryProvider.overrideWith(
    (ref) => MentoringRepositoryImpl(
      MentoringRemoteDataSource(ref.watch(dioProvider)),
      MentoringLocalDataSource(ref.watch(keyValueStoreProvider)),
    ),
  ),
];
