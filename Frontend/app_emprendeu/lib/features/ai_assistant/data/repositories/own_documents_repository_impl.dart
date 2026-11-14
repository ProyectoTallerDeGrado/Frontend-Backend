import 'dart:typed_data';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/knowledge_match.dart';
import '../../domain/entities/own_document.dart';
import '../../domain/repositories/own_documents_repository.dart';
import '../datasources/local_knowledge_store.dart';
import '../datasources/text_embedder.dart';
import '../datasources/text_extractor.dart';
import '../datasources/vector_search.dart';

/// Archivos propios: texto y vectores en el directorio de archivos del usuario
/// (se borra al cerrar sesión). El archivo original no se copia ni se sube.
class OwnDocumentsRepositoryImpl implements OwnDocumentsRepository {
  OwnDocumentsRepositoryImpl(
    this._store,
    this._embedder,
    this._extractor, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final LocalKnowledgeStore _store;
  final TextEmbedder _embedder;
  final TextExtractor _extractor;
  final DateTime Function() _clock;

  static const _batch = 16;

  @override
  Future<Result<List<OwnDocument>>> list() async {
    try {
      final index = await _store.load(_embedder.embedderId);
      final docs = index.documents.values.toList()
        ..sort(
          (a, b) =>
              (b.loadedAt ?? DateTime(0)).compareTo(a.loadedAt ?? DateTime(0)),
        );
      return Ok([
        for (final d in docs)
          OwnDocument(
            id: d.id,
            name: d.title,
            fragments: d.fragments.length,
            addedAt: d.loadedAt,
          ),
      ]);
    } on Object {
      return const Ok([]);
    }
  }

  @override
  Future<Result<String>> readText(PickedOwnFile file) async {
    try {
      return Ok(await _extractor.extract(file.path, file.name));
    } on Object {
      return const Err(
        FieldFailure(
          'file',
          'No se pudo leer el archivo. Revisa que no esté dañado ni protegido '
              'con contraseña.',
        ),
      );
    }
  }

  @override
  Future<Result<OwnDocument>> add(
    String name,
    List<String> chunks, {
    void Function(int done, int total)? onProgress,
  }) async {
    try {
      final index = await _store.load(_embedder.embedderId);
      final fragments = <StoredFragment>[];
      onProgress?.call(0, chunks.length);
      for (var i = 0; i < chunks.length; i += _batch) {
        final slice = chunks.sublist(
          i,
          i + _batch > chunks.length ? chunks.length : i + _batch,
        );
        final vectors = await _embedder.embedDocuments(slice);
        for (var j = 0; j < slice.length; j++) {
          fragments.add(
            StoredFragment(slice[j], Float32List.fromList(vectors[j])),
          );
        }
        onProgress?.call(fragments.length, chunks.length);
      }
      final now = _clock();
      final id = now.microsecondsSinceEpoch;
      // Mismo nombre otra vez: se reemplaza (p. ej. una versión nueva del plan).
      index.documents.removeWhere((_, d) => d.title == name);
      index.documents[id] = StoredDocument(
        id: id,
        title: name,
        loadedAt: now,
        fragments: fragments,
      );
      await _store.save(index);
      return Ok(
        OwnDocument(
          id: id,
          name: name,
          fragments: fragments.length,
          addedAt: now,
        ),
      );
    } on Object {
      return const Err(
        LocalAiFailure(
          'No se pudo analizar el archivo en tu celular. Intenta de nuevo.',
        ),
      );
    }
  }

  @override
  Future<Result<void>> remove(int id) async {
    try {
      final index = await _store.load(_embedder.embedderId);
      index.documents.remove(id);
      await _store.save(index);
      return const Ok(null);
    } on Object {
      return const Err(LocalAiFailure('No se pudo quitar el archivo.'));
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
      return Ok(searchIndex(index, q, limit, own: true));
    } on Object {
      return const Err(
        LocalAiFailure('La IA del celular no pudo buscar en tus archivos.'),
      );
    }
  }
}
