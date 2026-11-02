import 'dart:convert';

import '../../../../core/storage/key_value_store.dart';
import '../../../../core/storage/local_data_cleaner.dart';
import '../../domain/entities/commitment.dart';
import '../../domain/entities/progress_log.dart';
import '../models/pending_op.dart';

/// Cola de cambios pendientes y copia de la última lista descargada.
/// Todas las claves van bajo [userDataPrefix]: se borran al cerrar sesión.
class MentoringLocalDataSource {
  const MentoringLocalDataSource(this._store);

  final KeyValueStore _store;

  static const _opsKey = '${userDataPrefix}mentoring.pending_ops';
  static const _commitmentsKey = '${userDataPrefix}mentoring.commitments';
  static const _progressKey = '${userDataPrefix}mentoring.progress';

  // --- cola de pendientes ---------------------------------------------------

  Future<List<PendingOp>> readOps() async {
    final raw = await _store.read(_opsKey);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => PendingOp.fromJson(e as Map<String, dynamic>))
          .whereType<PendingOp>()
          .toList();
    } on FormatException {
      return [];
    }
  }

  Future<void> _writeOps(List<PendingOp> ops) async {
    if (ops.isEmpty) {
      await _store.remove(_opsKey);
    } else {
      await _store.write(
        _opsKey,
        jsonEncode(ops.map((o) => o.toJson()).toList()),
      );
    }
  }

  /// Guarda [op]. Para compromisos, el último cambio de un mismo compromiso reemplaza al anterior.
  Future<void> enqueue(PendingOp op) async {
    final ops = await readOps();
    if (op is PendingCommitmentOp) {
      ops.removeWhere(
        (o) => o is PendingCommitmentOp && o.commitmentId == op.commitmentId,
      );
    }
    await _writeOps([...ops, op]);
  }

  Future<void> removeCommitmentOp(int commitmentId) async {
    final ops = await readOps();
    ops.removeWhere(
      (o) => o is PendingCommitmentOp && o.commitmentId == commitmentId,
    );
    await _writeOps(ops);
  }

  Future<void> clearOps() => _writeOps([]);

  // --- copia de listas -----------------------------------------------------------

  Future<void> saveCommitments(List<Commitment> list) => _store.write(
    _commitmentsKey,
    jsonEncode([
      for (final c in list)
        {
          'id': c.id,
          'session': c.sessionId,
          'text': c.description,
          'done': c.done,
          'due': c.dueDate?.toUtc().toIso8601String(),
        },
    ]),
  );

  Future<List<Commitment>?> readCommitments() async {
    final raw = await _store.read(_commitmentsKey);
    if (raw == null) return null;
    try {
      return [
        for (final e in (jsonDecode(raw) as List).cast<Map<String, dynamic>>())
          Commitment(
            id: e['id'] as int,
            sessionId: e['session'] as int?,
            description: e['text'] as String,
            done: e['done'] as bool,
            dueDate: DateTime.tryParse(e['due'] as String? ?? '')?.toLocal(),
          ),
      ];
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  Future<void> saveProgress(List<ProgressLog> list) => _store.write(
    _progressKey,
    jsonEncode([
      for (final p in list.where((p) => !p.pendingSync))
        {
          'id': p.id,
          'ref': p.clientRef,
          'text': p.text,
          'at': p.createdAt.toUtc().toIso8601String(),
        },
    ]),
  );

  Future<List<ProgressLog>?> readProgress() async {
    final raw = await _store.read(_progressKey);
    if (raw == null) return null;
    try {
      return [
        for (final e in (jsonDecode(raw) as List).cast<Map<String, dynamic>>())
          ProgressLog(
            id: e['id'] as int?,
            clientRef: e['ref'] as String?,
            text: e['text'] as String,
            createdAt: DateTime.parse(e['at'] as String).toLocal(),
          ),
      ];
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }
}
