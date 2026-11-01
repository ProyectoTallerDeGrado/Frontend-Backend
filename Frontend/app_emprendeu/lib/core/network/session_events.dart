import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Avisos de sesión generados por la capa de red (p. ej. un 401 en cualquier
/// petición). La feature `auth` los escucha y cierra la sesión.
class SessionEvents {
  final _expired = StreamController<void>.broadcast();

  Stream<void> get onExpired => _expired.stream;
  void notifyExpired() => _expired.add(null);
  void dispose() => _expired.close();
}

final sessionEventsProvider = Provider<SessionEvents>((ref) {
  final events = SessionEvents();
  ref.onDispose(events.dispose);
  return events;
});
