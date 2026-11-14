import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../domain/entities/knowledge_match.dart';
import '../../domain/entities/local_knowledge_status.dart';
import '../../domain/repositories/local_knowledge_repository.dart';
import '../datasources/knowledge_remote_data_source.dart';
import '../datasources/local_knowledge_store.dart';
import '../datasources/text_embedder.dart';
import '../datasources/vector_search.dart';

class LocalKnowledgeRepositoryImpl implements LocalKnowledgeRepository {
  LocalKnowledgeRepositoryImpl(
    this._remote,
    this._store,
    this._embedder, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final KnowledgeRemoteDataSource _remote;
  final LocalKnowledgeStore _store;
  final TextEmbedder _embedder;
  final DateTime Function() _clock;

  /// Fragmentos por llamada al modelo: acota la memoria con libros grandes.
  static const _batch = 16;

  static LocalKnowledgeStatus _statusOf(StoredIndex index) =>
      LocalKnowledgeStatus(
        documents: index.documents.length,
        fragments: index.fragmentCount,
        syncedAt: index.syncedAt,
      );

  @override
  Future<Result<LocalKnowledgeStatus>> status() async {
    try {
      return Ok(_statusOf(await _store.load(_embedder.embedderId)));
    } on Object {
      return const Ok(LocalKnowledgeStatus.empty);
    }
  }

  @override
  Future<Result<LocalKnowledgeStatus>> sync({
    void Function(int done, int total)? onProgress,
  }) async {
    try {
      final index = await _store.load(_embedder.embedderId);
      final remote = await _remote.index();
      final wanted = {for (final d in remote.documentos) d.id: d};

      // Retirados en el servidor (inactivos): se borran del celular.
      index.documents.removeWhere((id, _) => !wanted.containsKey(id));

      // Nuevos o recargados (otra fecha de carga o distinto número de fragmentos).
      final pending = remote.documentos.where((d) {
        final local = index.documents[d.id];
        return local == null ||
            local.loadedAt != d.fechaCarga ||
            local.fragments.length != d.totalFragmentos;
      }).toList();

      var done = 0;
      onProgress?.call(done, pending.length);
      for (final doc in pending) {
        final texts = [
          for (final f in await _remote.fragments(doc.id)) f.contenido,
        ];
        final fragments = <StoredFragment>[];
        for (var i = 0; i < texts.length; i += _batch) {
          final slice = texts.sublist(
            i,
            i + _batch > texts.length ? texts.length : i + _batch,
          );
          final vectors = await _embedder.embedDocuments(slice);
          for (var j = 0; j < slice.length; j++) {
            fragments.add(
              StoredFragment(slice[j], Float32List.fromList(vectors[j])),
            );
          }
        }
        index.documents[doc.id] = StoredDocument(
          id: doc.id,
          title: doc.titulo,
          loadedAt: doc.fechaCarga,
          fragments: fragments,
        );
        // Se guarda por documento: si se corta, lo ya hecho no se repite.
        await _store.save(index);
        onProgress?.call(++done, pending.length);
      }
      index.syncedAt = _clock();
      await _store.save(index);
      return Ok(_statusOf(index));
    } on DioException catch (e) {
      return Err(mapDioException(e));
    } on Object {
      return const Err(
        LocalAiFailure(
          'No se pudieron preparar los documentos en tu celular. '
          'Intenta de nuevo.',
        ),
      );
    }
  }

  @override
  Future<Result<List<KnowledgeMatch>>> search(
    String query, {
    required int limit,
  }) async {
    try {
      final index = await _store.load(_embedder.embedderId);
      if (index.fragmentCount == 0) return const Ok([]);
      final q = await _embedder.embedQuery(query);
      return Ok(searchIndex(index, q, limit));
    } on Object {
      return const Err(
        LocalAiFailure('La IA del celular no pudo buscar en los documentos.'),
      );
    }
  }
}
