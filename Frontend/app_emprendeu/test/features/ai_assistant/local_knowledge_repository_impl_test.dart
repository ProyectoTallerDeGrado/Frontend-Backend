import 'dart:io';

import 'package:app_emprendeu/features/ai_assistant/data/datasources/knowledge_remote_data_source.dart';
import 'package:app_emprendeu/features/ai_assistant/data/datasources/local_knowledge_store.dart';
import 'package:app_emprendeu/features/ai_assistant/data/datasources/text_embedder.dart';
import 'package:app_emprendeu/features/ai_assistant/data/models/knowledge_dto.dart';
import 'package:app_emprendeu/features/ai_assistant/data/repositories/local_knowledge_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

const _keywords = ['costos', 'marketing', 'ventas'];

/// Vectores por conteo de palabras clave (como el doble del backend).
class _KeywordEmbedder implements TextEmbedder {
  _KeywordEmbedder([this.embedderId = 'emb-a']);

  @override
  final String embedderId;
  int embedded = 0;

  List<double> _vec(String t) => [
    for (final k in _keywords) k.allMatches(t.toLowerCase()).length.toDouble(),
  ];

  @override
  Future<List<List<double>>> embedDocuments(List<String> texts) async {
    embedded += texts.length;
    return [for (final t in texts) _vec(t)];
  }

  @override
  Future<List<double>> embedQuery(String text) async => _vec(text);
}

class _FakeRemote implements KnowledgeRemoteDataSource {
  List<IndexDocumentDto> docs = [];
  Map<int, List<String>> texts = {};
  int fragmentCalls = 0;

  @override
  Future<KnowledgeIndexDto> index() async => KnowledgeIndexDto(
    modeloEmbeddings: 'nomic-embed-text',
    dimension: 768,
    documentos: docs,
  );

  @override
  Future<List<FragmentDto>> fragments(int documentId) async {
    fragmentCalls++;
    return [for (final t in texts[documentId]!) FragmentDto(contenido: t)];
  }
}

IndexDocumentDto _doc(int id, String title, int total, [DateTime? at]) =>
    IndexDocumentDto(
      id: id,
      titulo: title,
      totalFragmentos: total,
      fechaCarga: at ?? DateTime.utc(2026, 11, 1),
    );

void main() {
  late Directory dir;
  late _FakeRemote remote;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('knowledge_test');
    remote = _FakeRemote()
      ..docs = [_doc(1, 'Guía de costos', 2), _doc(2, 'Guía de marketing', 1)]
      ..texts = {
        1: ['Separa tus costos fijos', 'Con los costos sacas el equilibrio'],
        2: ['El marketing en redes atrae clientes'],
      };
  });

  tearDown(() => dir.delete(recursive: true));

  LocalKnowledgeRepositoryImpl repo(TextEmbedder embedder) =>
      LocalKnowledgeRepositoryImpl(
        remote,
        LocalKnowledgeStore(() async => dir),
        embedder,
      );

  test('sincroniza, busca el documento correcto y persiste en disco', () async {
    final embedder = _KeywordEmbedder();
    final status = (await repo(embedder).sync()).valueOrNull!;
    expect(status.documents, 2);
    expect(status.fragments, 3);
    expect(status.syncedAt, isNotNull);
    expect(embedder.embedded, 3);

    // otra instancia (app reabierta) lee el archivo sin volver a sincronizar
    final fresh = repo(_KeywordEmbedder());
    final found = (await fresh.search(
      '¿cómo hago marketing?',
      limit: 2,
    )).valueOrNull!;
    expect(found.first.title, 'Guía de marketing');
    expect(found.first.score, closeTo(1, 1e-6));
  });

  test('la segunda sincronización solo trae lo que cambió', () async {
    final embedder = _KeywordEmbedder();
    final r = repo(embedder);
    await r.sync();
    remote.fragmentCalls = 0;
    embedder.embedded = 0;

    await r.sync(); // nada cambió
    expect(remote.fragmentCalls, 0);
    expect(embedder.embedded, 0);

    // se retira el de costos y llega uno nuevo de ventas
    remote.docs = [_doc(2, 'Guía de marketing', 1), _doc(3, 'Ventas', 1)];
    remote.texts[3] = ['Mejora tus ventas'];
    final status = (await r.sync()).valueOrNull!;
    expect(status.documents, 2);
    expect(remote.fragmentCalls, 1);
    final found = (await r.search('costos', limit: 5)).valueOrNull!;
    expect(found.any((m) => m.title == 'Guía de costos'), isFalse);
  });

  test('otro modelo de embeddings descarta los vectores viejos', () async {
    await repo(_KeywordEmbedder('emb-a')).sync();
    final other = repo(_KeywordEmbedder('emb-b'));
    expect((await other.status()).valueOrNull!.documents, 0);
    expect((await other.search('costos', limit: 3)).valueOrNull, isEmpty);
  });

  test('sin documentos la búsqueda devuelve vacío', () async {
    final found = await repo(_KeywordEmbedder()).search('costos', limit: 3);
    expect(found.valueOrNull, isEmpty);
  });
}
