import 'dart:convert';
import 'dart:io';

import 'package:app_emprendeu/core/storage/local_data_cleaner.dart';
import 'package:app_emprendeu/features/ai_assistant/data/datasources/local_knowledge_store.dart';
import 'package:app_emprendeu/features/ai_assistant/data/datasources/text_embedder.dart';
import 'package:app_emprendeu/features/ai_assistant/data/datasources/text_extractor.dart';
import 'package:app_emprendeu/features/ai_assistant/data/repositories/own_documents_repository_impl.dart';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

class _KeywordEmbedder implements TextEmbedder {
  @override
  String get embedderId => 'emb';

  List<double> _vec(String t) => [
    for (final k in ['café', 'costos', 'canvas'])
      k.allMatches(t.toLowerCase()).length.toDouble(),
  ];

  @override
  Future<List<List<double>>> embedDocuments(List<String> texts) async => [
    for (final t in texts) _vec(t),
  ];

  @override
  Future<List<double>> embedQuery(String text) async => _vec(text);
}

/// `.docx` mínimo: un ZIP con `word/document.xml`.
List<int> _docx(List<String> paragraphs) {
  final body = paragraphs
      .map((p) => '<w:p><w:r><w:t>$p</w:t></w:r></w:p>')
      .join();
  final xml =
      '<?xml version="1.0" encoding="UTF-8"?>'
      '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
      '<w:body>$body<w:p/></w:body></w:document>';
  final archive = Archive()
    ..addFile(ArchiveFile.bytes('word/document.xml', utf8.encode(xml)));
  return ZipEncoder().encodeBytes(archive);
}

void main() {
  late Directory dir;

  setUp(() async => dir = await Directory.systemTemp.createTemp('own_docs'));
  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  OwnDocumentsRepositoryImpl repo() => OwnDocumentsRepositoryImpl(
    LocalKnowledgeStore(() async => dir, fileName: 'own.json'),
    _KeywordEmbedder(),
    const TextExtractor(),
  );

  test('agrega, lista, busca y quita archivos propios', () async {
    final r = repo();
    final added = (await r.add('plan.pdf', [
      'Vendo café en ferias',
      'Mis costos son bajos',
    ])).valueOrNull!;
    expect(added.fragments, 2);

    final found = (await r.search(
      '¿cómo vendo más café?',
      limit: 3,
    )).valueOrNull!;
    expect(found.first.own, isTrue);
    expect(found.first.title, 'plan.pdf');
    expect(found.first.text, 'Vendo café en ferias');

    // otra instancia lee lo guardado en disco
    expect((await repo().list()).valueOrNull!.map((d) => d.name), ['plan.pdf']);

    await r.remove(added.id);
    expect((await r.list()).valueOrNull, isEmpty);
  });

  test('el mismo nombre reemplaza la versión anterior', () async {
    final r = repo();
    await r.add('plan.pdf', ['versión 1']);
    await r.add('plan.pdf', ['versión 2 con canvas']);
    final docs = (await r.list()).valueOrNull!;
    expect(docs, hasLength(1));
    final found = (await r.search('canvas', limit: 1)).valueOrNull!;
    expect(found.single.text, 'versión 2 con canvas');
  });

  test('cerrar sesión borra los archivos y otra cuenta no los ve', () async {
    final r = repo();
    await r.add('plan.pdf', ['Vendo café']);
    await LocalDataCleaner(
      InMemoryKeyValueStore(),
      () async => dir,
    ).clearUserData();
    // la misma instancia (caché en memoria) tampoco los devuelve
    expect((await r.list()).valueOrNull, isEmpty);
    expect((await r.search('café', limit: 3)).valueOrNull, isEmpty);
  });

  group('lectura de texto', () {
    test('DOCX: un bloque por párrafo, sin los vacíos', () {
      expect(
        TextExtractor.docxText(
          _docx(['Mi modelo canvas', 'Segmento: jóvenes']),
        ),
        'Mi modelo canvas\n\nSegmento: jóvenes',
      );
    });

    test('un DOCX dañado da FormatException', () {
      expect(
        () => TextExtractor.docxText(utf8.encode('no es un zip')),
        throwsFormatException,
      );
    });

    test('TXT en UTF-8 con BOM y en Latin-1', () {
      expect(
        TextExtractor.plainText([0xEF, 0xBB, 0xBF, ...utf8.encode('Año')]),
        'Año',
      );
      expect(TextExtractor.plainText(latin1.encode('Año')), 'Año');
    });

    test('lee el archivo del disco y lo agrega por el repositorio', () async {
      final file = File('${dir.path}/plan.docx')
        ..writeAsBytesSync(_docx(['Vendo café']));
      final text = await const TextExtractor().extract(file.path, 'plan.docx');
      expect(text, 'Vendo café');
    });
  });
}
