import 'package:dio/dio.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../../../core/utils/client_ref.dart';
import '../../domain/entities/commitment.dart';
import '../../domain/entities/progress_log.dart';
import '../../domain/entities/sync_summary.dart';
import '../../domain/repositories/mentoring_repository.dart';
import '../datasources/mentoring_local_data_source.dart';
import '../datasources/mentoring_remote_data_source.dart';
import '../models/pending_op.dart';

class MentoringRepositoryImpl implements MentoringRepository {
  const MentoringRepositoryImpl(this._remote, this._local);

  final MentoringRemoteDataSource _remote;
  final MentoringLocalDataSource _local;

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Result.ok(await action());
    } on DioException catch (e) {
      return Result.err(mapDioException(e));
    } on TypeError {
      return const Result.err(
        UnknownFailure('Respuesta inválida del servidor.'),
      );
    }
  }

  // --- compromisos ------------------------------------------------------------

  /// Aplica sobre la lista los cambios que aún no llegaron al servidor.
  List<Commitment> _overlay(List<Commitment> list, List<PendingOp> ops) {
    final pending = {
      for (final op in ops.whereType<PendingCommitmentOp>())
        op.commitmentId: op.done,
    };
    return [
      for (final c in list)
        pending.containsKey(c.id)
            ? c.copyWith(done: pending[c.id], pendingSync: true)
            : c,
    ];
  }

  @override
  Future<Result<List<Commitment>>> getCommitments() async {
    final ops = await _local.readOps();
    final remote = await _guard(
      () async =>
          (await _remote.commitments()).map((d) => d.toEntity()).toList(),
    );
    switch (remote) {
      case Ok(:final value):
        await _local.saveCommitments(value);
        return Result.ok(_overlay(value, ops));
      case Err(:final failure):
        if (failure is NetworkFailure) {
          final cached = await _local.readCommitments();
          if (cached != null) return Result.ok(_overlay(cached, ops));
        }
        return Result.err(failure);
    }
  }

  @override
  Future<Result<Commitment>> setCommitmentDone(
    Commitment commitment,
    bool done,
  ) async {
    final result = await _guard(
      () => _remote.setCommitmentDone(commitment.id, done),
    );
    switch (result) {
      case Ok(:final value):
        await _local.removeCommitmentOp(commitment.id);
        return Result.ok(value.toEntity());
      case Err(:final failure):
        if (failure is NetworkFailure) {
          await _local.enqueue(
            PendingCommitmentOp(commitment.id, done, DateTime.now()),
          );
          return Result.ok(commitment.copyWith(done: done, pendingSync: true));
        }
        return Result.err(failure);
    }
  }

  // --- avances -----------------------------------------------------------------

  List<ProgressLog> _pendingLogs(List<PendingOp> ops, int? ventureId) => [
    for (final op in ops.whereType<PendingProgressOp>().toList().reversed)
      if (op.ventureId == null ||
          ventureId == null ||
          op.ventureId == ventureId)
        ProgressLog(
          clientRef: op.clientRef,
          text: op.text,
          createdAt: op.at,
          pendingSync: true,
        ),
  ];

  @override
  Future<Result<List<ProgressLog>>> getProgressLogs({int? ventureId}) async {
    final ops = await _local.readOps();
    final remote = await _guard(
      () async =>
          (await _remote.progress(ventureId: ventureId))
              .map((d) => d.toEntity())
              .toList(),
    );
    switch (remote) {
      case Ok(:final value):
        await _local.saveProgress(value);
        return Result.ok([..._pendingLogs(ops, ventureId), ...value]);
      case Err(:final failure):
        if (failure is NetworkFailure) {
          final cached = await _local.readProgress();
          if (cached != null) {
            return Result.ok([..._pendingLogs(ops, ventureId), ...cached]);
          }
        }
        return Result.err(failure);
    }
  }

  @override
  Future<Result<ProgressLog>> logProgress(String text, {int? ventureId}) async {
    final ref = generateClientRef();
    final result = await _guard(
      () => _remote.logProgress(text, ref, ventureId: ventureId),
    );
    switch (result) {
      case Ok(:final value):
        return Result.ok(value.toEntity());
      case Err(:final failure):
        if (failure is NetworkFailure) {
          final now = DateTime.now();
          await _local.enqueue(
            PendingProgressOp(ref, text, now, ventureId: ventureId),
          );
          return Result.ok(
            ProgressLog(
              clientRef: ref,
              text: text,
              createdAt: now,
              pendingSync: true,
            ),
          );
        }
        return Result.err(failure);
    }
  }

  // --- sincronización -----------------------------------------------------------

  @override
  Future<int> pendingCount() async => (await _local.readOps()).length;

  @override
  Future<Result<SyncSummary>> syncPending() async {
    final ops = await _local.readOps();
    if (ops.isEmpty) return const Result.ok(SyncSummary(synced: 0));
    final result = await _guard(() => _remote.sync(ops));
    switch (result) {
      case Ok(:final value):
        // Lo que el servidor rechazó se descarta: reenviarlo no cambiaría la respuesta.
        await _local.clearOps();
        return Result.ok(
          SyncSummary(
            synced: value.avances.length + value.compromisos.length,
            errors: value.errores,
          ),
        );
      case Err(:final failure):
        return Result.err(failure);
    }
  }
}
