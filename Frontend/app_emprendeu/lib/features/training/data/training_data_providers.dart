import 'package:flutter_riverpod/misc.dart' show Override;

import '../../../core/network/providers.dart';
import '../presentation/controllers/training_providers.dart';
import 'datasources/training_remote_data_source.dart';
import 'repositories/training_repository_impl.dart';

final List<Override> trainingDataOverrides = [
  trainingRepositoryProvider.overrideWith(
    (ref) => TrainingRepositoryImpl(
      TrainingRemoteDataSource(ref.watch(dioProvider)),
    ),
  ),
];
