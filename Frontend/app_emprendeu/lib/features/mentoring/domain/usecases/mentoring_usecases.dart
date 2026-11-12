import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../entities/commitment.dart';
import '../entities/progress_log.dart';
import '../entities/sync_summary.dart';
import '../repositories/mentoring_repository.dart';

class GetCommitmentsUseCase {
  const GetCommitmentsUseCase(this._repository);
  final MentoringRepository _repository;

  Future<Result<List<Commitment>>> call() => _repository.getCommitments();
}

class SetCommitmentDoneUseCase {
  const SetCommitmentDoneUseCase(this._repository);
  final MentoringRepository _repository;

  Future<Result<Commitment>> call(Commitment commitment, bool done) =>
      _repository.setCommitmentDone(commitment, done);
}

class GetProgressLogsUseCase {
  const GetProgressLogsUseCase(this._repository);
  final MentoringRepository _repository;

  Future<Result<List<ProgressLog>>> call({int? ventureId}) =>
      _repository.getProgressLogs(ventureId: ventureId);
}

class LogProgressUseCase {
  const LogProgressUseCase(this._repository);
  final MentoringRepository _repository;

  Future<Result<ProgressLog>> call(String text, {int? ventureId}) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return Future.value(
        const Result.err(
          FieldFailure('text', 'Describe tu avance antes de guardar.'),
        ),
      );
    }
    return _repository.logProgress(trimmed, ventureId: ventureId);
  }
}

class GetPendingCountUseCase {
  const GetPendingCountUseCase(this._repository);
  final MentoringRepository _repository;

  Future<int> call() => _repository.pendingCount();
}

class SyncPendingUseCase {
  const SyncPendingUseCase(this._repository);
  final MentoringRepository _repository;

  Future<Result<SyncSummary>> call() => _repository.syncPending();
}
