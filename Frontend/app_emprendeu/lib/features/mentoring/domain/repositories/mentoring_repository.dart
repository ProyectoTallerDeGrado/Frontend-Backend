import '../../../../core/error/result.dart';
import '../entities/commitment.dart';
import '../entities/progress_log.dart';
import '../entities/sync_summary.dart';

/// Compromisos y avances del emprendedor, con soporte sin conexión.
abstract interface class MentoringRepository {
  /// Compromisos del usuario. Sin red devuelve la última copia guardada.
  Future<Result<List<Commitment>>> getCommitments();

  /// Marca o desmarca un compromiso. Sin red lo guarda en el dispositivo
  /// (`pendingSync = true`) para enviarlo después.
  Future<Result<Commitment>> setCommitmentDone(
    Commitment commitment,
    bool done,
  );

  /// Avances de [ventureId] (sin indicarlo, del primer emprendimiento).
  Future<Result<List<ProgressLog>>> getProgressLogs({int? ventureId});

  /// Registra un avance. Sin red lo guarda en el dispositivo para enviarlo después.
  Future<Result<ProgressLog>> logProgress(String text, {int? ventureId});

  /// Cambios guardados en el dispositivo que aún no llegaron al servidor.
  Future<int> pendingCount();

  /// Envía lo pendiente en un solo lote.
  Future<Result<SyncSummary>> syncPending();
}
