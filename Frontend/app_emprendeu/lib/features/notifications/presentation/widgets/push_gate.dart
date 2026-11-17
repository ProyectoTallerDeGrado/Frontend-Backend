import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/index.dart';
import '../../domain/entities/app_notification.dart';
import '../controllers/push_controller.dart';

/// Envuelve la app (en `MaterialApp.builder`): arranca el push con la sesión,
/// muestra el aviso breve de lo que llega con la app abierta y abre la pantalla
/// del push que el usuario tocó.
class PushGate extends ConsumerStatefulWidget {
  const PushGate({
    super.key,
    required this.messengerKey,
    required this.onOpenRoute,
    required this.child,
  });

  final GlobalKey<ScaffoldMessengerState> messengerKey;
  final void Function(String route) onOpenRoute;
  final Widget child;

  @override
  ConsumerState<PushGate> createState() => _PushGateState();
}

class _PushGateState extends ConsumerState<PushGate> {
  final _subs = <StreamSubscription<Object?>>[];

  @override
  void initState() {
    super.initState();
    final push = ref.read(pushControllerProvider);
    _subs
      ..add(push.banners.listen(_showBanner))
      ..add(push.opens.listen(widget.onOpenRoute));
    ref.listenManual(authControllerProvider, (_, next) {
      if (next.isLoading) return;
      push.onSession(loggedIn: next.value != null);
    }, fireImmediately: true);
  }

  void _showBanner(PushNotice notice) {
    final route = safeRoute(notice.route);
    final title = notice.title ?? 'Nuevo aviso';
    widget.messengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          content: Semantics(
            liveRegion: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if ((notice.body ?? '').isNotEmpty)
                  Text(
                    notice.body!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          action: route == null
              ? null
              : SnackBarAction(
                  label: 'Ver',
                  onPressed: () => widget.onOpenRoute(route),
                ),
        ),
      );
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
