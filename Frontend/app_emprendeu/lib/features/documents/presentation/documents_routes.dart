import 'package:go_router/go_router.dart';

import 'screens/documents_screen.dart';

abstract final class DocumentsRoutes {
  static const list = '/documents';
}

/// Pantalla de documentos (se agrega en `app/router.dart`). Recibe el id del emprendimiento
/// en `extra`.
final List<RouteBase> documentsRoutes = [
  GoRoute(
    path: DocumentsRoutes.list,
    builder: (context, state) => DocumentsScreen(
      ventureId: state.extra is int ? state.extra as int : null,
    ),
  ),
];
