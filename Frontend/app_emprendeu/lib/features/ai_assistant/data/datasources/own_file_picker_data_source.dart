import 'dart:io';

import 'package:file_picker/file_picker.dart';

import '../../domain/entities/own_document.dart';
import '../../domain/repositories/own_documents_repository.dart';

/// Selector de archivos del sistema (`file_picker`) para la IA local.
class FilePickerOwnFilePicker implements OwnFilePicker {
  const FilePickerOwnFilePicker();

  @override
  Future<PickedOwnFile?> pick(List<String> allowedExtensions) async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
    );
    final path = file?.path;
    if (file == null || path == null) return null;
    return PickedOwnFile(
      name: file.name,
      path: path,
      sizeBytes: await File(path).length(),
    );
  }
}
