import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/result.dart';
import '../../../auth/index.dart';
import '../../../documents/index.dart';
import '../../domain/entities/own_document.dart';
import '../../domain/repositories/own_documents_repository.dart';
import '../../domain/usecases/own_documents_usecases.dart';

/// Contratos de los archivos propios; las implementaciones van en `app/providers.dart`.
final ownDocumentsRepositoryProvider = Provider<OwnDocumentsRepository>(
  (ref) => throw UnimplementedError(
    'ownDocumentsRepositoryProvider sin implementación',
  ),
);

final ownFilePickerProvider = Provider<OwnFilePicker>(
  (ref) => throw UnimplementedError('ownFilePickerProvider sin implementación'),
);

final listOwnDocumentsUseCaseProvider = Provider(
  (ref) => ListOwnDocumentsUseCase(ref.watch(ownDocumentsRepositoryProvider)),
);

final pickOwnFileUseCaseProvider = Provider(
  (ref) => PickOwnFileUseCase(ref.watch(ownFilePickerProvider)),
);

final addOwnDocumentUseCaseProvider = Provider(
  (ref) => AddOwnDocumentUseCase(ref.watch(ownDocumentsRepositoryProvider)),
);

final removeOwnDocumentUseCaseProvider = Provider(
  (ref) => RemoveOwnDocumentUseCase(ref.watch(ownDocumentsRepositoryProvider)),
);

/// Pantalla «Mis archivos para la IA».
class OwnDocumentsState {
  const OwnDocumentsState({
    required this.documents,
    this.adding,
    this.done = 0,
    this.total = 0,
    this.error,
    this.notice,
  });

  final List<OwnDocument> documents;

  /// Nombre del archivo que se está analizando; `null` si no hay ninguno.
  final String? adding;
  final int done;
  final int total;
  final String? error;

  /// Aviso de éxito («Listo: plan.pdf»).
  final String? notice;

  OwnDocumentsState copyWith({
    List<OwnDocument>? documents,
    String? Function()? adding,
    int? done,
    int? total,
    String? Function()? error,
    String? Function()? notice,
  }) => OwnDocumentsState(
    documents: documents ?? this.documents,
    adding: adding != null ? adding() : this.adding,
    done: done ?? this.done,
    total: total ?? this.total,
    error: error != null ? error() : this.error,
    notice: notice != null ? notice() : this.notice,
  );
}

class OwnDocumentsController extends AsyncNotifier<OwnDocumentsState> {
  @override
  Future<OwnDocumentsState> build() async {
    // Otra cuenta, otra lista (los archivos se borran al cerrar sesión).
    ref.watch(authControllerProvider.select((s) => s.value?.user.id));
    final docs = (await ref.watch(
      listOwnDocumentsUseCaseProvider,
    )()).getOrThrow();
    return OwnDocumentsState(documents: docs);
  }

  /// Elige un archivo del teléfono y lo analiza. Cancelar el selector no hace nada.
  Future<void> pickAndAdd() async {
    final current = state.value;
    if (current == null || current.adding != null) return;
    final file = await ref.read(pickOwnFileUseCaseProvider)();
    if (file == null) return;
    await _add(current, file);
  }

  /// Trae un documento que el emprendedor ya subió al CIE-U (CU30) y lo analiza
  /// en el celular. La copia queda en el almacenamiento privado del usuario.
  Future<void> addFromVenture(Evidence document) async {
    final current = state.value;
    if (current == null || current.adding != null) return;
    state = AsyncData(
      current.copyWith(
        adding: () => document.name,
        done: 0,
        total: 0,
        error: () => null,
        notice: () => null,
      ),
    );
    final downloaded = await ref.read(downloadDocumentUseCaseProvider)(
      document,
    );
    switch (downloaded) {
      case Ok(:final value):
        await _add(
          current,
          PickedOwnFile(
            name: value.name,
            path: value.path,
            sizeBytes: value.sizeBytes,
          ),
        );
      case Err(:final failure):
        state = AsyncData(
          current.copyWith(adding: () => null, error: () => failure.message),
        );
    }
  }

  Future<void> _add(OwnDocumentsState current, PickedOwnFile file) async {
    state = AsyncData(
      current.copyWith(
        adding: () => file.name,
        done: 0,
        total: 0,
        error: () => null,
        notice: () => null,
      ),
    );
    final result = await ref.read(addOwnDocumentUseCaseProvider)(
      file,
      onProgress: (done, total) {
        final now = state.value;
        if (now != null && now.adding != null) {
          state = AsyncData(now.copyWith(done: done, total: total));
        }
      },
    );
    final after = state.value ?? current;
    switch (result) {
      case Ok(:final value):
        state = AsyncData(
          after.copyWith(
            documents: [
              value,
              ...after.documents.where((d) => d.name != value.name),
            ],
            adding: () => null,
            notice: () => 'Listo: la IA ya puede usar «${value.name}».',
          ),
        );
      case Err(:final failure):
        state = AsyncData(
          after.copyWith(adding: () => null, error: () => failure.message),
        );
    }
  }

  Future<void> remove(int id) async {
    final current = state.value;
    if (current == null || current.adding != null) return;
    final result = await ref.read(removeOwnDocumentUseCaseProvider)(id);
    state = AsyncData(switch (result) {
      Ok() => current.copyWith(
        documents: current.documents.where((d) => d.id != id).toList(),
        notice: () => null,
        error: () => null,
      ),
      Err(:final failure) => current.copyWith(error: () => failure.message),
    });
  }
}

final ownDocumentsControllerProvider =
    AsyncNotifierProvider<OwnDocumentsController, OwnDocumentsState>(
      OwnDocumentsController.new,
    );
