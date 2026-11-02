import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/evidence.dart';
import '../../domain/repositories/documents_repository.dart';
import '../../domain/repositories/evidence_picker.dart';
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

final uploadEvidenceUseCaseProvider = Provider(
  (ref) => UploadEvidenceUseCase(ref.watch(documentsRepositoryProvider)),
);
final getVentureEvidenceUseCaseProvider = Provider(
  (ref) => GetVentureEvidenceUseCase(ref.watch(documentsRepositoryProvider)),
);

/// Archivos de un emprendimiento (la evidencia se agrupa por `milestoneId`).
final ventureEvidenceProvider = FutureProvider.autoDispose
    .family<List<Evidence>, int>(
      (ref, ventureId) async =>
          (await ref.watch(getVentureEvidenceUseCaseProvider)(ventureId))
              .getOrThrow(),
    );
