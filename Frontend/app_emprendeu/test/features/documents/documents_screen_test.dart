import 'package:app_emprendeu/core/error/failure.dart';
import 'package:app_emprendeu/features/documents/domain/entities/evidence.dart';
import 'package:app_emprendeu/features/documents/domain/entities/picked_file.dart';
import 'package:app_emprendeu/features/documents/domain/usecases/documents_usecases.dart';
import 'package:app_emprendeu/features/ventures/domain/entities/venture.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../../support/test_app.dart';
import '../auth/fake_auth_repository.dart';
import 'fake_documents.dart';

const _venture = Venture(id: 1, name: 'Sabores del Oriente');

FakeDocumentsRepository _repo() => FakeDocumentsRepository()
  ..files.addAll([
    const Evidence(id: 1, name: 'plan.pdf'),
    const Evidence(id: 2, name: 'foto.png', milestoneId: 5),
  ]);

Future<void> _open(
  WidgetTester tester, {
  required FakeDocumentsRepository documents,
  FakeEvidencePicker? picker,
  FakeFileOpener? opener,
}) async {
  await pumpApp(
    tester,
    TestWorld(
      auth: FakeAuthRepository(token: 'tok-1'),
      ventures: FakeVenturesRepository(venture: _venture),
      documents: documents,
      picker: picker,
      opener: opener,
    ),
  );
  await tester.tap(find.text('Perfil'));
  await settle(tester);
  final button = find.text('Documentos');
  await tester.ensureVisible(button);
  await tester.pump(const Duration(milliseconds: 200));
  await tester.tap(button);
  await settle(tester);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 200));
  await tester.tap(finder);
  await settle(tester);
}

void main() {
  group('casos de uso (CU30)', () {
    test('rechaza una extensión no permitida al subir un documento', () async {
      final repo = FakeDocumentsRepository();
      final result = await UploadDocumentUseCase(repo)(
        ventureId: 1,
        file: const PickedFile(name: 'virus.exe', path: '/tmp/virus.exe'),
      );
      expect((result.failureOrNull as FieldFailure).field, 'file');
      expect(repo.uploadCalls, 0);
    });

    test('subir un documento no lo ata a ningún hito', () async {
      final repo = FakeDocumentsRepository();
      await UploadDocumentUseCase(repo)(
        ventureId: 3,
        file: const PickedFile(name: 'Plan.PDF', path: '/tmp/Plan.PDF'),
      );
      expect(repo.lastVentureId, 3);
      expect(repo.lastMilestoneId, isNull);
    });

    test('abrir descarga primero y luego abre el archivo', () async {
      final repo = FakeDocumentsRepository();
      final opener = FakeFileOpener();
      final result = await OpenDocumentUseCase(repo, opener)(9, 'plan.pdf');
      expect(result.failureOrNull, isNull);
      expect(repo.lastDownloadName, 'plan.pdf');
      expect(opener.lastPath, '/tmp/9-plan.pdf');
    });

    test('si el dispositivo no puede abrirlo, lo avisa; si la descarga falla, no intenta abrir', () async {
      final repo = FakeDocumentsRepository();
      final noApp = FakeFileOpener(canOpen: false);
      final cannot = await OpenDocumentUseCase(repo, noApp)(1, 'x.pdf');
      expect(cannot.failureOrNull?.message, contains('no hay una app'));

      repo.downloadFailure = const NetworkFailure();
      final opener = FakeFileOpener();
      final failed = await OpenDocumentUseCase(repo, opener)(1, 'x.pdf');
      expect(failed.failureOrNull, isA<NetworkFailure>());
      expect(opener.opens, 0);
    });
  });

  testWidgets('lista los documentos del emprendimiento', (tester) async {
    await _open(tester, documents: _repo());
    expect(find.text('plan.pdf'), findsOneWidget);
    expect(find.text('foto.png'), findsOneWidget);
    expect(find.text('Evidencia de un hito'), findsOneWidget);
  });

  testWidgets('sin documentos lo dice', (tester) async {
    await _open(tester, documents: FakeDocumentsRepository());
    expect(find.text('Todavía no hay documentos.'), findsOneWidget);
  });

  testWidgets('sube un documento elegido en el dispositivo', (tester) async {
    final documents = FakeDocumentsRepository();
    final picker = FakeEvidencePicker(
      file: const PickedFile(name: 'comprobante.pdf', path: '/tmp/c.pdf'),
    );
    await _open(tester, documents: documents, picker: picker);

    await _tap(tester, find.text('Subir documento'));
    expect(documents.uploadCalls, 1);
    expect(documents.lastVentureId, 1);
    expect(documents.lastMilestoneId, isNull);
    expect(find.text('comprobante.pdf'), findsOneWidget);
    expect(find.text('Documento subido.'), findsOneWidget);
  });

  testWidgets('un tipo de archivo no válido no se sube y se explica', (
    tester,
  ) async {
    final documents = FakeDocumentsRepository();
    final picker = FakeEvidencePicker(
      file: const PickedFile(name: 'virus.exe', path: '/tmp/virus.exe'),
    );
    await _open(tester, documents: documents, picker: picker);
    await _tap(tester, find.text('Subir documento'));
    expect(documents.uploadCalls, 0);
    expect(
      find.textContaining('Ese tipo de archivo no es válido'),
      findsOneWidget,
    );
  });

  testWidgets('cancelar el selector no sube nada', (tester) async {
    final documents = FakeDocumentsRepository();
    await _open(
      tester,
      documents: documents,
      picker: FakeEvidencePicker(file: null),
    );
    await _tap(tester, find.text('Subir documento'));
    expect(documents.uploadCalls, 0);
  });

  testWidgets('descarga y abre un documento', (tester) async {
    final documents = _repo();
    final opener = FakeFileOpener();
    await _open(tester, documents: documents, opener: opener);

    await _tap(tester, find.byTooltip('Descargar plan.pdf'));
    expect(documents.downloadCalls, 1);
    expect(opener.lastPath, '/tmp/1-plan.pdf');
  });

  testWidgets('si no hay app para abrirlo, avisa', (tester) async {
    await _open(
      tester,
      documents: _repo(),
      opener: FakeFileOpener(canOpen: false),
    );
    await _tap(tester, find.byTooltip('Descargar plan.pdf'));
    expect(find.textContaining('no hay una app para abrirlo'), findsOneWidget);
  });

  testWidgets('eliminar pide confirmación y solo borra si se acepta', (
    tester,
  ) async {
    final documents = _repo();
    await _open(tester, documents: documents);

    await _tap(tester, find.byTooltip('Eliminar plan.pdf'));
    expect(find.text('Eliminar documento'), findsOneWidget);
    await _tap(tester, find.text('Cancelar'));
    expect(documents.deleteCalls, 0);
    expect(find.text('plan.pdf'), findsOneWidget);

    await _tap(tester, find.byTooltip('Eliminar plan.pdf'));
    await _tap(tester, find.widgetWithText(FilledButton, 'Eliminar'));
    expect(documents.deleteCalls, 1);
    expect(documents.lastDeletedId, 1);
    expect(find.text('plan.pdf'), findsNothing);
    expect(find.text('foto.png'), findsOneWidget);
  });
}
