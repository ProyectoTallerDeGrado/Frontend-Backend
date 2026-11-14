import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../entities/downloaded_document.dart';
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

class UploadEvidenceUseCase {
  const UploadEvidenceUseCase(this._repository);
  final DocumentsRepository _repository;

  Future<Result<Evidence>> call({
    required int ventureId,
    int? milestoneId,
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

class DeleteDocumentUseCase {
  const DeleteDocumentUseCase(this._repository);
  final DocumentsRepository _repository;

  Future<Result<void>> call(int documentId) => _repository.delete(documentId);
}

/// Descarga un documento del emprendimiento al celular (CU30).
class DownloadDocumentUseCase {
  const DownloadDocumentUseCase(this._repository);
  final DocumentsRepository _repository;

  Future<Result<DownloadedDocument>> call(Evidence document) =>
      _repository.download(document);
}

/// Descarga (si hace falta) y abre el documento con la app del sistema (CU30).
class OpenDocumentUseCase {
  const OpenDocumentUseCase(this._repository, this._opener);
  final DocumentsRepository _repository;
  final FileOpener _opener;

  Future<Result<void>> call(Evidence document) async {
    final downloaded = await _repository.download(document);
    return switch (downloaded) {
      Ok(:final value) => _opener.open(value.path),
      Err(:final failure) => Err(failure),
    };
  }
}
