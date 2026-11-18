import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/notifications/index.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class App extends ConsumerWidget {
  const App({super.key, this.useGoogleFonts = true});

  /// Para mostrar avisos (push recibido con la app abierta) sobre cualquier pantalla.
  static final messengerKey = GlobalKey<ScaffoldMessengerState>();

  /// Los tests lo desactivan para no descargar fuentes.
  final bool useGoogleFonts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'EmprendeU',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(useGoogleFonts: useGoogleFonts),
      routerConfig: ref.watch(routerProvider),
      scaffoldMessengerKey: messengerKey,
      builder: (context, child) => PushGate(
        messengerKey: messengerKey,
        onOpenRoute: (route) => ref.read(routerProvider).go(route),
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
