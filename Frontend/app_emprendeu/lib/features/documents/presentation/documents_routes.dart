import 'package:go_router/go_router.dart';

import 'screens/documents_screen.dart';

abstract final class DocumentsRoutes {
  static const list = '/venture/documents';
}

/// Documentos del emprendimiento (se agregan en `app/router.dart`).
final List<RouteBase> documentsRoutes = [
  GoRoute(
    path: DocumentsRoutes.list,
    builder: (context, state) => const DocumentsScreen(),
  ),
];
