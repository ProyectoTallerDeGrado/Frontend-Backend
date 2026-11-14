import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../entities/own_document.dart';
import '../repositories/own_documents_repository.dart';
import 'chunk_text.dart';

/// Formatos que la IA del celular sabe leer.
const ownDocumentExtensions = ['pdf', 'docx', 'txt', 'md'];

/// Tope por archivo: más que esto tardaría demasiado en analizarse en el teléfono.
const maxOwnDocumentBytes = 20 * 1024 * 1024;

/// Tope de partes por archivo (≈ 160 páginas de texto).
const maxOwnDocumentChunks = 400;

class ListOwnDocumentsUseCase {
  const ListOwnDocumentsUseCase(this._repository);
  final OwnDocumentsRepository _repository;

  Future<Result<List<OwnDocument>>> call() => _repository.list();
}

class PickOwnFileUseCase {
  const PickOwnFileUseCase(this._picker);
  final OwnFilePicker _picker;

  Future<PickedOwnFile?> call() => _picker.pick(ownDocumentExtensions);
}

/// Lee, trocea y analiza un archivo del emprendedor, todo dentro del celular.
class AddOwnDocumentUseCase {
  const AddOwnDocumentUseCase(this._repository);
  final OwnDocumentsRepository _repository;

  Future<Result<OwnDocument>> call(
    PickedOwnFile file, {
    void Function(int done, int total)? onProgress,
  }) async {
    final ext = file.name.contains('.')
        ? file.name.split('.').last.toLowerCase()
        : '';
    if (!ownDocumentExtensions.contains(ext)) {
      return const Err(
        FieldFailure(
          'file',
          'Formato no válido. Usa PDF, Word (.docx), TXT o MD.',
        ),
      );
    }
    if (file.sizeBytes > maxOwnDocumentBytes) {
      return const Err(
        FieldFailure('file', 'El archivo es muy grande (máximo 20 MB).'),
      );
    }
    final read = await _repository.readText(file);
    if (read case Err(:final failure)) return Err(failure);
    final chunks = chunkText(read.valueOrNull!);
    if (chunks.isEmpty) {
      return const Err(
        FieldFailure(
          'file',
          'No encontré texto en el archivo. Si es un PDF escaneado (una imagen), '
              'no se puede leer.',
        ),
      );
    }
    return _repository.add(
      file.name,
      chunks.length > maxOwnDocumentChunks
          ? chunks.sublist(0, maxOwnDocumentChunks)
          : chunks,
      onProgress: onProgress,
    );
  }
}

class RemoveOwnDocumentUseCase {
  const RemoveOwnDocumentUseCase(this._repository);
  final OwnDocumentsRepository _repository;

  Future<Result<void>> call(int id) => _repository.remove(id);
}
