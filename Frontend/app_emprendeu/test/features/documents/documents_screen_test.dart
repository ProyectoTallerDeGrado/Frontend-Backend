import 'package:app_emprendeu/core/error/failure.dart';
import 'package:app_emprendeu/features/documents/domain/entities/evidence.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';
import '../auth/fake_auth_repository.dart';
import 'fake_documents.dart';

Future<void> _open(
  WidgetTester tester,
  FakeDocumentsRepository docs, {
  FakeFileOpener? opener,
}) async {
  await pumpApp(
    tester,
    TestWorld(
      auth: FakeAuthRepository(token: 'tok-1'),
      documents: docs,
      opener: opener,
    ),
    height: 1600,
  );
  await tester.tap(find.text('Perfil'));
  await settle(tester);
  final entry = find.text('Documentos');
  await tester.ensureVisible(entry);
  await tester.pump(const Duration(milliseconds: 200));
  await tester.tap(entry);
  await settle(tester);
}

void main() {
  testWidgets('lista los documentos y sube uno nuevo', (tester) async {
    final docs = FakeDocumentsRepository();
    docs.files.add(const Evidence(id: 1, name: 'plan.pdf'));
    await _open(tester, docs);
    expect(find.text('plan.pdf'), findsOneWidget);

    await tester.tap(find.text('Subir documento'));
    await settle(tester);
    expect(docs.uploadCalls, 1);
    expect(find.text('prototipo.pdf'), findsOneWidget);
  });

  testWidgets('CU30: abrir descarga el documento y lo abre', (tester) async {
    final docs = FakeDocumentsRepository();
    docs.files.add(const Evidence(id: 7, name: 'plan.pdf'));
    final opener = FakeFileOpener();
    await _open(tester, docs, opener: opener);
    await tester.tap(find.byTooltip('Abrir plan.pdf'));
    await settle(tester);
    expect(docs.downloaded, [7]);
    expect(opener.opened, ['/tmp/plan.pdf']);
  });

  testWidgets('CU30: sin app para abrirlo, se explica', (tester) async {
    final docs = FakeDocumentsRepository();
    docs.files.add(const Evidence(id: 7, name: 'plan.pdf'));
    final opener = FakeFileOpener()
      ..failure = const UnknownFailure(
        'No tienes una app para abrir este tipo de archivo.',
      );
    await _open(tester, docs, opener: opener);
    await tester.tap(find.byTooltip('Abrir plan.pdf'));
    await settle(tester);
    expect(find.textContaining('No tienes una app'), findsOneWidget);
  });
}
