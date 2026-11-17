import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_notification.dart';
import 'notifications_providers.dart';

/// Conecta el push del celular con la sesión: registra el token al entrar,
/// lo invalida al salir, y avisa a la UI de lo que llega o se toca.
class PushController {
  PushController(this._ref);

  final Ref _ref;
  final _banners = StreamController<PushNotice>.broadcast();
  final _opens = StreamController<String>.broadcast();
  final _subs = <StreamSubscription<Object?>>[];
  bool _listening = false;
  bool? _loggedIn;

  /// Push recibido con la app abierta: la UI lo muestra como aviso breve.
  Stream<PushNotice> get banners => _banners.stream;

  /// Rutas a abrir porque el usuario tocó un push (ya validadas).
  Stream<String> get opens => _opens.stream;

  /// Llamar cada vez que cambia la sesión.
  Future<void> onSession({required bool loggedIn}) async {
    if (_loggedIn == loggedIn) return;
    _loggedIn = loggedIn;
    final messaging = _ref.read(pushMessagingProvider);
    if (!loggedIn) {
      // Sin sesión no hay token de la API para borrar el dispositivo: se invalida
      // el token de FCM y el backend lo borra en el siguiente envío.
      await messaging.deleteToken();
      return;
    }
    if (!await messaging.start()) return;
    final token = await messaging.token();
    if (token != null) await _register(token);
    if (_listening) return;
    _listening = true;
    _subs
      ..add(messaging.onTokenRefresh.listen(_register))
      ..add(
        messaging.onForeground.listen((notice) {
          _refresh();
          _banners.add(notice);
        }),
      )
      ..add(messaging.onOpened.listen(_open));
    final initial = await messaging.initialNotice();
    if (initial != null) _open(initial);
  }

  Future<void> _register(String token) async {
    if (_loggedIn != true) return;
    final messaging = _ref.read(pushMessagingProvider);
    await _ref.read(registerPushDeviceUseCaseProvider)(
      token,
      messaging.platform,
    );
  }

  void _open(PushNotice notice) {
    _refresh();
    final route = safeRoute(notice.route);
    if (route != null) _opens.add(route);
  }

  void _refresh() {
    _ref
      ..invalidate(unreadCountProvider)
      ..invalidate(notificationsProvider);
  }

  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _banners.close();
    _opens.close();
  }
}

final pushControllerProvider = Provider<PushController>((ref) {
  final controller = PushController(ref);
  ref.onDispose(controller.dispose);
  return controller;
});
