import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Origen de cambios de red (se sustituye en tests).
abstract interface class ConnectivitySource {
  Future<bool> isOnline();
  Stream<bool> get onChanged;
}

class PlatformConnectivitySource implements ConnectivitySource {
  PlatformConnectivitySource([Connectivity? connectivity])
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  static bool _hasNetwork(List<ConnectivityResult> r) =>
      r.any((c) => c != ConnectivityResult.none);

  @override
  Future<bool> isOnline() async =>
      _hasNetwork(await _connectivity.checkConnectivity());

  @override
  Stream<bool> get onChanged =>
      _connectivity.onConnectivityChanged.map(_hasNetwork);
}

final connectivitySourceProvider = Provider<ConnectivitySource>(
  (ref) => PlatformConnectivitySource(),
);

/// `true` = hay conexión. Combina el estado del sistema con lo que ve la app:
/// una petición que falla por red ([markOffline]) fuerza «sin conexión» hasta
/// que el sistema avise de que volvió la red o una petición tenga éxito.
class OnlineController extends Notifier<bool> {
  @override
  bool build() {
    final source = ref.watch(connectivitySourceProvider);
    final sub = source.onChanged.listen((online) => state = online);
    ref.onDispose(sub.cancel);
    unawaited(source.isOnline().then((online) => state = online));
    return true;
  }

  void markOffline() => state = false;
  void markOnline() => state = true;
}

final onlineProvider = NotifierProvider<OnlineController, bool>(
  OnlineController.new,
);
