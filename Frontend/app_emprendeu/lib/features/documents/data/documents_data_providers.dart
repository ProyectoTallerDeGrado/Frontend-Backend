import 'package:flutter_riverpod/misc.dart' show Override;

import '../../../core/network/providers.dart';
import '../../../core/storage/providers.dart';
import '../presentation/controllers/documents_providers.dart';
import 'datasources/documents_remote_data_source.dart';
import 'datasources/file_picker_data_source.dart';
import 'datasources/open_filex_file_opener.dart';
import 'repositories/documents_repository_impl.dart';

final List<Override> documentsDataOverrides = [
  documentsRepositoryProvider.overrideWith(
    (ref) => DocumentsRepositoryImpl(
      DocumentsRemoteDataSource(ref.watch(dioProvider)),
      ref.watch(userFilesDirectoryProvider),
    ),
  ),
  evidencePickerProvider.overrideWithValue(const FilePickerEvidencePicker()),
  fileOpenerProvider.overrideWithValue(const OpenFilexFileOpener()),
];
