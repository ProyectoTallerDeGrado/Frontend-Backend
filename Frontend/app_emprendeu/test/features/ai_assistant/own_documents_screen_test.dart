import 'package:app_emprendeu/features/ai_assistant/domain/entities/local_ai_status.dart';
import 'package:app_emprendeu/features/ai_assistant/domain/entities/own_document.dart';
import 'package:app_emprendeu/features/documents/domain/entities/evidence.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';
import '../auth/fake_auth_repository.dart';
import '../documents/fake_documents.dart';
import 'fake_local_ai_repository.dart';
import 'fake_own_documents.dart';

const _plan = PickedOwnFile(
  name: 'plan.pdf',
  path: '/tmp/plan.pdf',
  sizeBytes: 2048,
);

/// Perfil → «Mis archivos para la IA» (la IA ya está instalada).
Future<TestWorld> _openFiles(
  WidgetTester tester, {
  FakeOwnDocumentsRepository? docs,
  FakeOwnFilePicker? picker,
  FakeDocumentsRepository? documents,
}) async {
  final world = TestWorld(
    auth: FakeAuthRepository(token: 'tok-1'),
    localAi: FakeLocalAiRepository(current: LocalAiStatus.installed),
    ownDocuments: docs,
    ownPicker: picker,
    documents: documents,
  );
  await pumpApp(tester, world, height: 2400);
  await tester.tap(find.text('Perfil'));
  await settle(tester);
  await tester.tap(find.text('Mis archivos para la IA'));
  await settle(tester);
  return world;
}

Future<void> _fromPhone(WidgetTester tester) async {
  await tester.tap(find.text('Agregar archivo'));
  await settle(tester);
  await tester.tap(find.text('Desde tu teléfono'));
  await settle(tester);
}

void main() {
  testWidgets('sin archivos explica la privacidad y los formatos', (
    tester,
  ) async {
    await _openFiles(tester);
    expect(find.textContaining('solo en este celular'), findsOneWidget);
    expect(find.text('Aún no agregaste archivos'), findsOneWidget);
    expect(find.textContaining('PDF, Word (.docx), TXT o MD'), findsOneWidget);
  });

  testWidgets('agregar un archivo lo analiza y lo lista', (tester) async {
    final world = await _openFiles(tester, picker: FakeOwnFilePicker(_plan));
    await _fromPhone(tester);
    expect(find.textContaining('ya puede usar «plan.pdf»'), findsOneWidget);
    expect(find.text('plan.pdf'), findsOneWidget);
    expect(world.ownDocuments.documents.single.name, 'plan.pdf');
  });

  testWidgets('cancelar el selector no cambia nada', (tester) async {
    final world = await _openFiles(tester, picker: FakeOwnFilePicker());
    await _fromPhone(tester);
    expect(find.text('Aún no agregaste archivos'), findsOneWidget);
    expect(world.ownDocuments.documents, isEmpty);
  });

  testWidgets('un formato no válido se explica', (tester) async {
    await _openFiles(
      tester,
      picker: FakeOwnFilePicker(
        const PickedOwnFile(name: 'foto.jpg', path: '/tmp/f', sizeBytes: 9),
      ),
    );
    await _fromPhone(tester);
    expect(find.textContaining('Formato no válido'), findsOneWidget);
  });

  testWidgets('quitar pide confirmación', (tester) async {
    final docs = FakeOwnDocumentsRepository(
      documents: [
        OwnDocument(
          id: 1,
          name: 'canvas.docx',
          fragments: 3,
          addedAt: DateTime.now(),
        ),
      ],
    );
    await _openFiles(tester, docs: docs);
    expect(find.text('canvas.docx'), findsOneWidget);
    await tester.tap(find.byTooltip('Quitar canvas.docx'));
    await settle(tester);
    expect(find.textContaining('no se borra'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Quitar'));
    await settle(tester);
    expect(find.text('canvas.docx'), findsNothing);
    expect(docs.documents, isEmpty);
  });

  testWidgets('CU30: agrega un documento que ya subió al emprendimiento', (
    tester,
  ) async {
    final documents = FakeDocumentsRepository();
    documents.files.addAll(const [
      Evidence(id: 7, name: 'canvas.pdf'),
      Evidence(id: 8, name: 'logo.png'), // la IA no lee imágenes
    ]);
    final world = await _openFiles(tester, documents: documents);
    await tester.tap(find.text('Agregar archivo'));
    await settle(tester);
    await tester.tap(find.text('Desde los documentos de tu emprendimiento'));
    await settle(tester);
    expect(find.text('canvas.pdf'), findsOneWidget);
    expect(find.text('logo.png'), findsNothing);

    await tester.tap(find.text('canvas.pdf'));
    await settle(tester);
    expect(documents.downloaded, [7]);
    expect(world.ownDocuments.documents.single.name, 'canvas.pdf');
    expect(find.textContaining('ya puede usar «canvas.pdf»'), findsOneWidget);
  });
}
