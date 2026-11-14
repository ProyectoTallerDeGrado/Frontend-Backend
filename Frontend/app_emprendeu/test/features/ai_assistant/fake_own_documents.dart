import 'package:app_emprendeu/core/error/failure.dart';
import 'package:app_emprendeu/core/error/result.dart';
import 'package:app_emprendeu/features/ai_assistant/domain/entities/knowledge_match.dart';
import 'package:app_emprendeu/features/ai_assistant/domain/entities/own_document.dart';
import 'package:app_emprendeu/features/ai_assistant/domain/repositories/own_documents_repository.dart';

/// Archivos propios en memoria. [texts] simula el contenido de cada archivo.
class FakeOwnDocumentsRepository implements OwnDocumentsRepository {
  FakeOwnDocumentsRepository({
    List<OwnDocument>? documents,
    this.matches = const [],
  }) : documents = documents ?? [];

  List<OwnDocument> documents;
  List<KnowledgeMatch> matches;
  Map<String, String> texts = {};
  Failure? readFailure;
  List<String> lastChunks = [];
  int _nextId = 100;

  @override
  Future<Result<List<OwnDocument>>> list() async => Ok(List.of(documents));

  @override
  Future<Result<String>> readText(PickedOwnFile file) async {
    if (readFailure case final f?) return Err(f);
    return Ok(texts[file.name] ?? 'Mi plan de negocio.\n\nVendo café.');
  }

  @override
  Future<Result<OwnDocument>> add(
    String name,
    List<String> chunks, {
    void Function(int done, int total)? onProgress,
  }) async {
    lastChunks = chunks;
    onProgress?.call(chunks.length, chunks.length);
    final doc = OwnDocument(
      id: _nextId++,
      name: name,
      fragments: chunks.length,
      addedAt: DateTime.now(),
    );
    documents = [doc, ...documents.where((d) => d.name != name)];
    return Ok(doc);
  }

  @override
  Future<Result<void>> remove(int id) async {
    documents = documents.where((d) => d.id != id).toList();
    return const Ok(null);
  }

  @override
  Future<Result<List<KnowledgeMatch>>> search(
    String query, {
    required int limit,
  }) async => Ok(matches.take(limit).toList());
}

/// Selector que devuelve [next] (o `null` = la persona canceló).
class FakeOwnFilePicker implements OwnFilePicker {
  FakeOwnFilePicker([this.next]);

  PickedOwnFile? next;
  List<String> lastExtensions = [];

  @override
  Future<PickedOwnFile?> pick(List<String> allowedExtensions) async {
    lastExtensions = allowedExtensions;
    return next;
  }
}
