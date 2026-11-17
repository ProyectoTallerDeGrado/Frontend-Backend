import 'package:flutter_riverpod/misc.dart' show Override;

import '../../../core/network/providers.dart';
import '../presentation/controllers/notifications_providers.dart';
import 'datasources/firebase_push_messaging.dart';
import 'datasources/notifications_remote_data_source.dart';
import 'repositories/notifications_repository_impl.dart';

/// Implementación de `data` para el contrato de `domain` de la feature.
final List<Override> notificationsDataOverrides = [
  notificationsRepositoryProvider.overrideWith(
    (ref) => NotificationsRepositoryImpl(
      NotificationsRemoteDataSource(ref.watch(dioProvider)),
    ),
  ),
  pushMessagingProvider.overrideWith((ref) => FirebasePushMessaging()),
];
