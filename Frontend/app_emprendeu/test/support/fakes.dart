import 'dart:async';

import 'package:app_emprendeu/core/connectivity/online_controller.dart';
import 'package:app_emprendeu/core/error/failure.dart';
import 'package:app_emprendeu/core/error/result.dart';
import 'package:app_emprendeu/core/storage/key_value_store.dart';
import 'package:app_emprendeu/core/storage/token_storage.dart';
import 'package:app_emprendeu/features/gamification/domain/entities/completion_result.dart';
import 'package:app_emprendeu/features/gamification/domain/entities/gamification_profile.dart';
import 'package:app_emprendeu/features/gamification/domain/entities/journey.dart';
import 'package:app_emprendeu/features/gamification/domain/repositories/gamification_repository.dart';
import 'package:app_emprendeu/features/mentoring/domain/entities/commitment.dart';
import 'package:app_emprendeu/features/mentoring/domain/entities/progress_log.dart';
import 'package:app_emprendeu/features/mentoring/domain/entities/sync_summary.dart';
import 'package:app_emprendeu/features/mentoring/domain/repositories/mentoring_repository.dart';
import 'package:app_emprendeu/features/ventures/domain/entities/milestone.dart';
import 'package:app_emprendeu/features/ventures/domain/entities/venture.dart';
import 'package:app_emprendeu/features/ventures/domain/repositories/ventures_repository.dart';

class InMemoryKeyValueStore implements KeyValueStore {
  final Map<String, String> data = {};

  @override
  Future<String?> read(String key) async => data[key];
  @override
  Future<void> write(String key, String value) async => data[key] = value;
  @override
  Future<void> remove(String key) async => data.remove(key);
  @override
  Future<void> removeWithPrefix(String prefix) async =>
      data.removeWhere((k, _) => k.startsWith(prefix));
}

class InMemoryTokenStorage implements TokenStorage {
  String? token;

  @override
  Future<String?> read() async => token;
  @override
  Future<void> write(String value) async => token = value;
  @override
  Future<void> clear() async => token = null;
}

/// Conectividad controlable desde el test.
class FakeConnectivity implements ConnectivitySource {
  FakeConnectivity([this.online = true]);

  bool online;
  final _controller = StreamController<bool>.broadcast();

  void set(bool value) {
    online = value;
    _controller.add(value);
  }

  @override
  Future<bool> isOnline() async => online;
  @override
  Stream<bool> get onChanged => _controller.stream;
}

class FakeVenturesRepository implements VenturesRepository {
  FakeVenturesRepository({
    this.venture,
    this.ventures,
    List<Milestone>? milestones,
  }) : milestones = milestones ?? [];

  /// Emprendimiento único (lo que usaban las pruebas antes de CU05).
  Venture? venture;

  /// Varios emprendimientos; si se indica, manda sobre [venture].
  List<Venture>? ventures;
  int createCalls = 0;
  int updateCalls = 0;
  String? lastUpdatedName;
  String? lastUpdatedSector;
  String? lastUpdatedDescription;
  final List<Milestone> milestones;
  int milestoneCalls = 0;

  @override
  Future<Result<Venture>> update(
    int ventureId, {
    required String name,
    String? description,
    String? sector,
  }) async {
    updateCalls++;
    lastUpdatedName = name;
    lastUpdatedSector = sector;
    lastUpdatedDescription = description;
    venture = Venture(
      id: ventureId,
      name: name,
      stageName: venture?.stageName,
      description: description,
      sector: sector,
      status: venture?.status,
    );
    return Result.ok(venture!);
  }

  @override
  Future<Result<List<Milestone>>> getMilestones(int ventureId) async =>
      Result.ok(List.of(milestones));

  @override
  Future<Result<Milestone>> createMilestone(
    int ventureId, {
    required String title,
    String? description,
  }) async {
    milestoneCalls++;
    final created = Milestone(
      id: 50 + milestoneCalls,
      title: title,
      description: description,
      done: false,
    );
    milestones.add(created);
    return Result.ok(created);
  }

  @override
  Future<Result<Milestone>> completeMilestone(int milestoneId) async {
    final i = milestones.indexWhere((h) => h.id == milestoneId);
    final done = Milestone(
      id: milestoneId,
      title: milestones[i].title,
      description: milestones[i].description,
      done: true,
      doneAt: DateTime.now(),
    );
    milestones[i] = done;
    return Result.ok(done);
  }

  @override
  Future<Result<List<Venture>>> getMine() async =>
      Result.ok(ventures ?? [?venture]);

  @override
  Future<Result<Venture>> create(String name) async {
    createCalls++;
    venture = Venture(id: 1, name: name, stageName: 'Preincubación');
    return Result.ok(venture!);
  }
}

const sampleStages = [
  JourneyStage(id: 1, name: 'Preincubación', status: StageStatus.done),
  JourneyStage(id: 2, name: 'Incubación', status: StageStatus.current),
  JourneyStage(id: 3, name: 'Crecimiento', status: StageStatus.locked),
];

Journey sampleJourney({int done = 2}) {
  const titles = [
    'Definir la propuesta de valor',
    'Entrevistar a 5 clientes potenciales',
    'Construir un prototipo mínimo',
    'Registrar ventas de prueba',
    'Presentar el plan financiero',
  ];
  return Journey(
    ventureId: 1,
    xp: 295,
    level: 2,
    stages: sampleStages,
    challenges: [
      for (var i = 0; i < titles.length; i++)
        JourneyChallenge(
          id: i + 1,
          title: titles[i],
          description: 'Descripción de ${titles[i]}',
          stageName: i < 2 ? 'Preincubación' : 'Incubación',
          xp: 100 + i * 25,
          status: i < done
              ? ChallengeStatus.done
              : (i == done ? ChallengeStatus.current : ChallengeStatus.locked),
        ),
    ],
  );
}

class FakeGamificationRepository implements GamificationRepository {
  FakeGamificationRepository({
    Journey? journey,
    this.profile,
    this.journeyFailure,
  }) : journey = journey ?? sampleJourney();

  Journey journey;
  GamificationProfile? profile;
  Failure? journeyFailure;
  int completeCalls = 0;
  Failure? completeFailure;

  /// Último emprendimiento pedido (para verificar el selector).
  int? lastVentureId;

  @override
  Future<Result<Journey>> getJourney({int? ventureId}) async {
    lastVentureId = ventureId;
    return journeyFailure != null
        ? Result.err(journeyFailure!)
        : Result.ok(journey);
  }

  @override
  Future<Result<GamificationProfile>> getProfile() async => Result.ok(
    profile ??
        const GamificationProfile(
          xp: 295,
          level: 2,
          nextLevelXp: 400,
          missingXp: 105,
          progressPct: 47.5,
        ),
  );

  @override
  Future<Result<CompletionResult>> completeChallenge(
    int challengeId, {
    int? ventureId,
  }) async {
    completeCalls++;
    if (completeFailure != null) return Result.err(completeFailure!);
    final updated = [
      for (final c in journey.challenges)
        c.id == challengeId
            ? JourneyChallenge(
                id: c.id,
                title: c.title,
                description: c.description,
                stageName: c.stageName,
                xp: c.xp,
                status: ChallengeStatus.done,
              )
            : c,
    ];
    // Desbloquea el siguiente.
    final firstLocked = updated.indexWhere(
      (c) => c.status == ChallengeStatus.locked,
    );
    if (firstLocked >= 0) {
      final c = updated[firstLocked];
      updated[firstLocked] = JourneyChallenge(
        id: c.id,
        title: c.title,
        description: c.description,
        stageName: c.stageName,
        xp: c.xp,
        status: ChallengeStatus.current,
      );
    }
    journey = Journey(
      ventureId: journey.ventureId,
      xp: journey.xp + 150,
      level: journey.level,
      stages: journey.stages,
      challenges: updated,
    );
    return Result.ok(
      CompletionResult(
        challengeId: challengeId,
        xpAwarded: 150,
        xpTotal: journey.xp,
        level: journey.level,
        leveledUp: false,
        newBadges: const [],
      ),
    );
  }
}

/// Compromisos y avances en memoria, con un interruptor de «sin conexión».
class FakeMentoringRepository implements MentoringRepository {
  FakeMentoringRepository({List<Commitment>? commitments})
    : commitments =
          commitments ??
          [
            Commitment(
              id: 1,
              sessionId: 1,
              description: 'Enviar guion de entrevista a la mentora',
              done: false,
              dueDate: DateTime(2026, 10, 22),
            ),
            Commitment(
              id: 2,
              sessionId: 1,
              description: 'Actualizar costos del prototipo',
              done: false,
              dueDate: DateTime(2026, 10, 26),
            ),
          ];

  List<Commitment> commitments;
  final List<ProgressLog> logs = [
    ProgressLog(
      id: 1,
      text: 'Primera entrevista realizada con 2 clientes potenciales.',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];
  final List<Object> pending = [];
  bool offline = false;
  int syncCalls = 0;

  @override
  Future<Result<List<Commitment>>> getCommitments() async =>
      Result.ok(commitments);

  @override
  Future<Result<Commitment>> setCommitmentDone(
    Commitment commitment,
    bool done,
  ) async {
    final updated = commitment.copyWith(done: done, pendingSync: offline);
    commitments = [
      for (final c in commitments) c.id == updated.id ? updated : c,
    ];
    if (offline) pending.add(updated);
    return Result.ok(updated);
  }

  @override
  Future<Result<List<ProgressLog>>> getProgressLogs({int? ventureId}) async =>
      Result.ok(List.of(logs));

  @override
  Future<Result<ProgressLog>> logProgress(String text, {int? ventureId}) async {
    final log = ProgressLog(
      id: offline ? null : logs.length + 1,
      text: text,
      createdAt: DateTime.now(),
      pendingSync: offline,
    );
    logs.insert(0, log);
    if (offline) pending.add(log);
    return Result.ok(log);
  }

  @override
  Future<int> pendingCount() async => pending.length;

  @override
  Future<Result<SyncSummary>> syncPending() async {
    syncCalls++;
    if (offline) return const Result.err(NetworkFailure());
    final count = pending.length;
    pending.clear();
    commitments = [for (final c in commitments) c.copyWith(pendingSync: false)];
    for (var i = 0; i < logs.length; i++) {
      final l = logs[i];
      if (l.pendingSync) {
        logs[i] = ProgressLog(
          id: i + 100,
          text: l.text,
          createdAt: l.createdAt,
        );
      }
    }
    return Result.ok(SyncSummary(synced: count));
  }
}
