import 'package:app_emprendeu/core/error/failure.dart';
import 'package:app_emprendeu/core/error/result.dart';
import 'package:app_emprendeu/features/documents/domain/entities/evidence.dart';
import 'package:app_emprendeu/features/documents/domain/entities/picked_file.dart';
import 'package:app_emprendeu/features/documents/domain/repositories/documents_repository.dart';
import 'package:app_emprendeu/features/documents/domain/repositories/evidence_picker.dart';

/// Repositorio de documentos en memoria. Puede simular que la subida falla.
class FakeDocumentsRepository implements DocumentsRepository {
  FakeDocumentsRepository({this.uploadFailure});

  final List<Evidence> files = [];
  Failure? uploadFailure;
  int uploadCalls = 0;
  int? lastMilestoneId;
  int? lastVentureId;

  @override
  Future<Result<Evidence>> upload({
    required int ventureId,
    int? milestoneId,
    required PickedFile file,
  }) async {
    uploadCalls++;
    lastMilestoneId = milestoneId;
    lastVentureId = ventureId;
    if (uploadFailure != null) return Result.err(uploadFailure!);
    final created = Evidence(
      id: 900 + uploadCalls,
      name: file.name,
      milestoneId: milestoneId,
    );
    files.add(created);
    return Result.ok(created);
  }

  int deleteCalls = 0;

  @override
  Future<Result<void>> delete(int documentId) async {
    deleteCalls++;
    files.removeWhere((f) => f.id == documentId);
    return const Result.ok(null);
  }

  @override
  Future<Result<List<Evidence>>> listForVenture(int ventureId) async =>
      Result.ok(List.of(files));
}

/// Selector que devuelve siempre el mismo archivo (o `null` = la persona cancela).
class FakeEvidencePicker implements EvidencePicker {
  FakeEvidencePicker({
    this.file = const PickedFile(
      name: 'prototipo.pdf',
      path: '/tmp/prototipo.pdf',
    ),
  });

  PickedFile? file;
  int picks = 0;

  @override
  Future<PickedFile?> pick() async {
    picks++;
    return file;
  }
}
