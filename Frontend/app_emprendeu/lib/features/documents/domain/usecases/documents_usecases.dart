import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../entities/evidence.dart';
import '../entities/picked_file.dart';
import '../repositories/documents_repository.dart';
import '../repositories/file_opener.dart';

/// Extensiones que acepta el servidor para evidencia.
const evidenceExtensions = [
  'pdf',
  'png',
  'jpg',
  'jpeg',
  'webp',
  'txt',
  'csv',
  'doc',
  'docx',
  'xls',
  'xlsx',
  'ppt',
  'pptx',
];

FieldFailure? _invalidExtension(String name) {
  final dot = name.lastIndexOf('.');
  final extension = dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
  if (evidenceExtensions.contains(extension)) return null;
  return const FieldFailure(
    'file',
    'Ese tipo de archivo no es válido. Usa PDF, imagen u hoja de documento.',
  );
}

class UploadEvidenceUseCase {
  const UploadEvidenceUseCase(this._repository);
  final DocumentsRepository _repository;

  Future<Result<Evidence>> call({
    required int ventureId,
    required int milestoneId,
    required PickedFile file,
  }) {
    final dot = file.name.lastIndexOf('.');
    final extension = dot < 0 ? '' : file.name.substring(dot + 1).toLowerCase();
    if (!evidenceExtensions.contains(extension)) {
      return Future.value(
        const Result.err(
          FieldFailure(
            'file',
            'Ese tipo de archivo no es válido. Usa PDF, imagen u hoja de documento.',
          ),
        ),
      );
    }
    return _repository.upload(
      ventureId: ventureId,
      milestoneId: milestoneId,
      file: file,
    );
  }
}

class GetVentureEvidenceUseCase {
  const GetVentureEvidenceUseCase(this._repository);
  final DocumentsRepository _repository;

  Future<Result<List<Evidence>>> call(int ventureId) =>
      _repository.listForVenture(ventureId);
}

/// Sube un documento al emprendimiento (sin vincularlo a un hito).
class UploadDocumentUseCase {
  const UploadDocumentUseCase(this._repository);
  final DocumentsRepository _repository;

  Future<Result<Evidence>> call({
    required int ventureId,
    required PickedFile file,
  }) {
    final invalid = _invalidExtension(file.name);
    if (invalid != null) return Future.value(Result.err(invalid));
    return _repository.upload(ventureId: ventureId, file: file);
  }
}

class DeleteDocumentUseCase {
  const DeleteDocumentUseCase(this._repository);
  final DocumentsRepository _repository;

  Future<Result<void>> call(int documentId) => _repository.delete(documentId);
}

/// Descarga el documento y lo abre. Si el dispositivo no tiene con qué abrirlo, avisa.
class OpenDocumentUseCase {
  const OpenDocumentUseCase(this._repository, this._opener);
  final DocumentsRepository _repository;
  final FileOpener _opener;

  Future<Result<void>> call(int documentId, String name) async {
    final downloaded = await _repository.download(documentId, name);
    final path = downloaded.valueOrNull;
    if (path == null) return Result.err(downloaded.failureOrNull!);
    final opened = await _opener.open(path);
    if (!opened) {
      return const Result.err(
        UnknownFailure(
          'Se descargó el archivo, pero no hay una app para abrirlo en este dispositivo.',
        ),
      );
    }
    return const Result.ok(null);
  }
}
