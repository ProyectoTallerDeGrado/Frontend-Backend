import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../entities/evidence.dart';
import '../entities/picked_file.dart';
import '../repositories/documents_repository.dart';

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
