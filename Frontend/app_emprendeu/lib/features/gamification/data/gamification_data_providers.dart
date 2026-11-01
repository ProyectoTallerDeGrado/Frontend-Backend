import 'package:flutter_riverpod/misc.dart' show Override;

import '../../../core/network/providers.dart';
import '../presentation/controllers/gamification_providers.dart';
import 'datasources/gamification_remote_data_source.dart';
import 'repositories/gamification_repository_impl.dart';

final List<Override> gamificationDataOverrides = [
  gamificationRepositoryProvider.overrideWith(
    (ref) => GamificationRepositoryImpl(
      GamificationRemoteDataSource(ref.watch(dioProvider)),
    ),
  ),
];
