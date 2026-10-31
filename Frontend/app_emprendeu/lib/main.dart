import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/providers.dart';

void main() {
  runApp(
    ProviderScope(
      overrides: appOverrides,
      // Los errores se muestran con «Reintentar»; sin reintentos automáticos de Riverpod.
      retry: (_, _) => null,
      child: const App(),
    ),
  );
}
