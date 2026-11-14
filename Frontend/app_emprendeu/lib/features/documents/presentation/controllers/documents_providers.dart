import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/evidence.dart';
import '../../domain/repositories/documents_repository.dart';
import '../../domain/repositories/evidence_picker.dart';
import '../../domain/repositories/file_opener.dart';
import '../../domain/usecases/documents_usecases.dart';

/// Contratos; las implementaciones se inyectan en `app/providers.dart`.
final documentsRepositoryProvider = Provider<DocumentsRepository>(
  (ref) => throw UnimplementedError(
    'documentsRepositoryProvider sin implementación',
  ),
);
final evidencePickerProvider = Provider<EvidencePicker>(
  (ref) =>
      throw UnimplementedError('evidencePickerProvider sin implementación'),
);

final fileOpenerProvider = Provider<FileOpener>(
  (ref) => throw UnimplementedError('fileOpenerProvider sin implementación'),
);

final downloadDocumentUseCaseProvider = Provider(
  (ref) => DownloadDocumentUseCase(ref.watch(documentsRepositoryProvider)),
);

final openDocumentUseCaseProvider = Provider(
  (ref) => OpenDocumentUseCase(
    ref.watch(documentsRepositoryProvider),
    ref.watch(fileOpenerProvider),
  ),
);

final uploadEvidenceUseCaseProvider = Provider(
  (ref) => UploadEvidenceUseCase(ref.watch(documentsRepositoryProvider)),
);
final getVentureEvidenceUseCaseProvider = Provider(
  (ref) => GetVentureEvidenceUseCase(ref.watch(documentsRepositoryProvider)),
);

final deleteDocumentUseCaseProvider = Provider(
  (ref) => DeleteDocumentUseCase(ref.watch(documentsRepositoryProvider)),
);

/// Archivos de un emprendimiento (la evidencia se agrupa por `milestoneId`).
final ventureEvidenceProvider = FutureProvider.autoDispose
    .family<List<Evidence>, int>(
      (ref, ventureId) async =>
          (await ref.watch(getVentureEvidenceUseCaseProvider)(ventureId))
              .getOrThrow(),
    );
