@Tags(['integration'])
library;

import 'dart:io';

import 'package:app_emprendeu/core/error/failure.dart';
import 'package:app_emprendeu/core/error/result.dart';
import 'package:app_emprendeu/core/network/auth_interceptor.dart';
import 'package:app_emprendeu/core/network/dio_client.dart';
import 'package:app_emprendeu/core/network/session_events.dart';
import 'package:app_emprendeu/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:app_emprendeu/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:app_emprendeu/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:app_emprendeu/features/auth/domain/usecases/login_usecase.dart';
import 'package:app_emprendeu/features/auth/domain/usecases/register_usecase.dart';
import 'package:app_emprendeu/features/gamification/data/datasources/gamification_remote_data_source.dart';
import 'package:app_emprendeu/features/gamification/data/repositories/gamification_repository_impl.dart';
import 'package:app_emprendeu/features/gamification/domain/entities/journey.dart';
import 'package:app_emprendeu/features/mentoring/data/datasources/mentoring_local_data_source.dart';
import 'package:app_emprendeu/features/mentoring/data/datasources/mentoring_remote_data_source.dart';
import 'package:app_emprendeu/features/mentoring/data/repositories/mentoring_repository_impl.dart';
import 'package:app_emprendeu/features/ventures/data/datasources/ventures_remote_data_source.dart';
import 'package:app_emprendeu/features/ventures/data/repositories/ventures_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

/// Recorre Inicio y Camino contra un backend real:
///
///     API_BASE_URL=http://localhost:8000/api/v1 \
///     flutter test --tags integration test/integration
void main() {
  final baseUrl = Platform.environment['API_BASE_URL'];
  final skip = baseUrl == null ? 'Define API_BASE_URL para correrla' : null;

  test(
    'emprendimiento, camino, avances y sincronización',
    skip: skip,
    () async {
      final tokens = InMemoryTokenStorage();
      final dio = createDio(baseUrl: baseUrl!)
        ..interceptors.add(AuthInterceptor(tokens, SessionEvents()));

      // 1. Cuenta nueva y sesión.
      final authRepo = AuthRepositoryImpl(
        AuthRemoteDataSource(dio),
        AuthLocalDataSource(tokens),
      );
      final login = LoginUseCase(authRepo);
      final email = 'it-${DateTime.now().microsecondsSinceEpoch}@correo.com';
      final session = await RegisterUseCase(authRepo, login)(
        fullName: 'Camila Integracion',
        email: email,
        password: 'clave-larga-1',
      );
      expect(session, isA<Ok>());

      // 2. Sin emprendimiento: no hay camino y se pide registrarlo.
      final ventures = VenturesRepositoryImpl(VenturesRemoteDataSource(dio));
      final gamification = GamificationRepositoryImpl(
        GamificationRemoteDataSource(dio),
      );
      expect((await ventures.getMine()).valueOrNull, isEmpty);
      expect(
        (await gamification.getJourney()).failureOrNull,
        isA<NoVentureFailure>(),
      );

      // 3. Registrar emprendimiento y ver el camino.
      final created = await ventures.create('Sabores IT');
      expect(created.valueOrNull?.stageName, 'Preincubación');
      final journey = (await gamification.getJourney()).getOrThrow();
      expect(journey.challenges, isNotEmpty);
      expect(journey.xp, 0);
      final next = journey.nextChallenge!;
      expect(next.status, ChallengeStatus.current);
      expect(journey.challenges.last.status, ChallengeStatus.locked);

      // 4. Cumplir el primer reto: suma XP y se desbloquea el siguiente.
      final done = (await gamification.completeChallenge(next.id)).getOrThrow();
      expect(done.xpAwarded, greaterThan(0));
      final profile = (await gamification.getProfile()).getOrThrow();
      expect(profile.xp, done.xpTotal);
      final after = (await gamification.getJourney()).getOrThrow();
      expect(after.doneCount, 1);
      expect(after.nextChallenge!.id, isNot(next.id));
      // Repetirlo no da XP otra vez.
      expect((await gamification.completeChallenge(next.id)).isErr, isTrue);

      // 5. Avance en línea.
      final store = InMemoryKeyValueStore();
      final online = MentoringRepositoryImpl(
        MentoringRemoteDataSource(dio),
        MentoringLocalDataSource(store),
      );
      expect(
        (await online.logProgress('Avance en línea')).valueOrNull?.pendingSync,
        isFalse,
      );

      // 6. Avance sin conexión: queda en el dispositivo y luego se sincroniza.
      final deadDio = createDio(baseUrl: 'http://127.0.0.1:9');
      final offline = MentoringRepositoryImpl(
        MentoringRemoteDataSource(deadDio),
        MentoringLocalDataSource(store),
      );
      final queued = (await offline.logProgress('Avance sin conexión'))
          .getOrThrow();
      expect(queued.pendingSync, isTrue);
      expect(await offline.pendingCount(), 1);

      final summary = (await online.syncPending()).getOrThrow();
      expect(summary.synced, 1);
      expect(await online.pendingCount(), 0);

      final logs = (await online.getProgressLogs()).getOrThrow();
      expect(
        logs.map((l) => l.text),
        containsAll(['Avance en línea', 'Avance sin conexión']),
      );
      expect(logs.every((l) => !l.pendingSync), isTrue);

      // 7. Compromisos: aún no hay ninguno (los asigna un mentor).
      expect((await online.getCommitments()).getOrThrow(), isEmpty);
    },
  );
}

extension on Result<Object?> {
  bool get isErr => this is Err;
}
