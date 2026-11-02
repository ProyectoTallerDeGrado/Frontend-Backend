import 'package:flutter_riverpod/misc.dart' show Override;

import '../../../core/network/providers.dart';
import '../../../core/storage/providers.dart';
import '../presentation/controllers/booking_providers.dart';
import '../presentation/controllers/mentoring_providers.dart';
import 'datasources/booking_remote_data_source.dart';
import 'datasources/mentoring_local_data_source.dart';
import 'datasources/mentoring_remote_data_source.dart';
import 'repositories/booking_repository_impl.dart';
import 'repositories/mentoring_repository_impl.dart';

final List<Override> mentoringDataOverrides = [
  bookingRepositoryProvider.overrideWith(
    (ref) =>
        BookingRepositoryImpl(BookingRemoteDataSource(ref.watch(dioProvider))),
  ),
  mentoringRepositoryProvider.overrideWith(
    (ref) => MentoringRepositoryImpl(
      MentoringRemoteDataSource(ref.watch(dioProvider)),
      MentoringLocalDataSource(ref.watch(keyValueStoreProvider)),
    ),
  ),
];
