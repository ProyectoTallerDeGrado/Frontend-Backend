import 'package:file_picker/file_picker.dart';

import '../../domain/entities/picked_file.dart';
import '../../domain/repositories/evidence_picker.dart';
import '../../domain/usecases/documents_usecases.dart';

/// Selector de archivos del sistema (`file_picker`).
class FilePickerEvidencePicker implements EvidencePicker {
  const FilePickerEvidencePicker();

  @override
  Future<PickedFile?> pick() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: evidenceExtensions,
    );
    final path = file?.path;
    if (file == null || path == null) return null;
    return PickedFile(name: file.name, path: path);
  }
}
