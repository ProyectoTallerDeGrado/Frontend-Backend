import 'package:app_emprendeu/core/error/failure.dart';
import 'package:app_emprendeu/features/ai_assistant/domain/entities/own_document.dart';
import 'package:app_emprendeu/features/ai_assistant/domain/usecases/own_documents_usecases.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_own_documents.dart';

PickedOwnFile _file(String name, {int size = 1000}) =>
    PickedOwnFile(name: name, path: '/tmp/$name', sizeBytes: size);

void main() {
  late FakeOwnDocumentsRepository repo;
  late AddOwnDocumentUseCase add;

  setUp(() {
    repo = FakeOwnDocumentsRepository();
    add = AddOwnDocumentUseCase(repo);
  });

  test('trocea el texto y lo guarda', () async {
    repo.texts['plan.pdf'] = 'Uno.\n\nDos.';
    final r = await add(_file('plan.pdf'));
    expect(r.valueOrNull!.name, 'plan.pdf');
    expect(repo.lastChunks, ['Uno.\n\nDos.']);
  });

  test('rechaza formatos que no sabe leer', () async {
    final r = await add(_file('foto.jpg'));
    expect((r.failureOrNull as FieldFailure).message, contains('Formato'));
    expect(repo.documents, isEmpty);
  });

  test('acepta la extensión en mayúsculas', () async {
    final r = await add(_file('PLAN.DOCX'));
    expect(r.failureOrNull, isNull);
  });

  test('rechaza archivos de más de 20 MB', () async {
    final r = await add(_file('libro.pdf', size: maxOwnDocumentBytes + 1));
    expect((r.failureOrNull as FieldFailure).message, contains('20 MB'));
  });

  test('un PDF sin texto (escaneado) se explica', () async {
    repo.texts['scan.pdf'] = '   ';
    final r = await add(_file('scan.pdf'));
    expect((r.failureOrNull as FieldFailure).message, contains('escaneado'));
  });

  test('un archivo enorme se recorta al tope de partes', () async {
    repo.texts['tesis.txt'] = List.filled(
      maxOwnDocumentChunks + 50,
      'x' * 790,
    ).join('\n\n');
    await add(_file('tesis.txt'));
    expect(repo.lastChunks, hasLength(maxOwnDocumentChunks));
  });

  test('el selector solo ofrece los formatos que se leen', () async {
    final picker = FakeOwnFilePicker();
    await PickOwnFileUseCase(picker)();
    expect(picker.lastExtensions, ownDocumentExtensions);
  });
}
