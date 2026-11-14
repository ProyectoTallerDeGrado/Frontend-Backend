@Tags(['integration'])
library;

import 'dart:io';

import 'package:app_emprendeu/core/error/failure.dart';
import 'package:app_emprendeu/core/error/result.dart';
import 'package:app_emprendeu/core/network/auth_interceptor.dart';
import 'package:app_emprendeu/core/network/dio_client.dart';
import 'package:app_emprendeu/core/network/session_events.dart';
import 'package:app_emprendeu/features/ai_assistant/data/datasources/assistant_remote_data_source.dart';
import 'package:app_emprendeu/features/ai_assistant/data/repositories/assistant_repository_impl.dart';
import 'package:app_emprendeu/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:app_emprendeu/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:app_emprendeu/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:app_emprendeu/features/auth/domain/usecases/login_usecase.dart';
import 'package:app_emprendeu/features/auth/domain/usecases/register_usecase.dart';
import 'package:app_emprendeu/features/mentoring/data/datasources/booking_remote_data_source.dart';
import 'package:app_emprendeu/features/mentoring/data/repositories/booking_repository_impl.dart';
import 'package:app_emprendeu/features/mentoring/domain/entities/history_event.dart';
import 'package:app_emprendeu/features/mentoring/domain/entities/history_filter.dart';
import 'package:app_emprendeu/features/mentoring/domain/entities/task.dart';
import 'package:app_emprendeu/features/needs/data/datasources/needs_remote_data_source.dart';
import 'package:app_emprendeu/features/needs/data/repositories/needs_repository_impl.dart';
import 'package:app_emprendeu/features/needs/domain/entities/venture_need.dart';
import 'package:app_emprendeu/features/ventures/data/datasources/ventures_remote_data_source.dart';
import 'package:app_emprendeu/features/ventures/data/repositories/ventures_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

/// Contrato móvil ↔ backend de CU11, CU19, CU22 y CU24:
///
///     API_BASE_URL=http://localhost:8000/api/v1 \
///     flutter test --tags integration test/integration/follow_up_backend_test.dart
void main() {
  final baseUrl = Platform.environment['API_BASE_URL'];
  final skip = baseUrl == null ? 'Define API_BASE_URL para correrla' : null;

  test(
    'tareas, historial filtrado, necesidades y conversaciones',
    skip: skip,
    () async {
      final tokens = InMemoryTokenStorage();
      final dio = createDio(baseUrl: baseUrl!)
        ..interceptors.add(AuthInterceptor(tokens, SessionEvents()));

      // Cuenta nueva con emprendimiento y un hito.
      final authRepo = AuthRepositoryImpl(
        AuthRemoteDataSource(dio),
        AuthLocalDataSource(tokens),
      );
      await RegisterUseCase(authRepo, LoginUseCase(authRepo))(
        fullName: 'Camila Seguimiento',
        email: 'it-${DateTime.now().microsecondsSinceEpoch}@correo.com',
        password: 'clave-larga-1',
      );
      final ventures = VenturesRepositoryImpl(VenturesRemoteDataSource(dio));
      final venture = (await ventures.create('Sabores Seguimiento'))
          .getOrThrow();
      final milestone = (await ventures.createMilestone(
        venture.id,
        title: 'Primer prototipo',
      )).getOrThrow();

      final booking = BookingRepositoryImpl(BookingRemoteDataSource(dio));

      // CU22: el hito aparece como tarea pendiente; filtrar por tipo y estado.
      final pending = (await booking.getTasks(const TaskFilter())).getOrThrow();
      expect(pending.map((t) => t.title), contains('Primer prototipo'));
      expect(pending.first.kind, TaskKind.milestone);
      expect(
        (await booking.getTasks(const TaskFilter(kind: TaskKind.commitment)))
            .getOrThrow(),
        isEmpty,
      );
      await ventures.completeMilestone(milestone.id);
      expect(
        (await booking.getTasks(const TaskFilter())).getOrThrow(),
        isEmpty,
      );
      final done = (await booking.getTasks(
        const TaskFilter(state: TaskState.done),
      )).getOrThrow();
      expect(done.single.state, TaskState.done);

      // CU19: el filtro de tipos viaja como tipo=a&tipo=b y el servidor lo aplica.
      final all = (await booking.getHistory(ventureId: venture.id))
          .getOrThrow();
      expect(
        all.map((e) => e.kind),
        containsAll([HistoryKind.milestone, HistoryKind.stage]),
      );
      final onlyMilestones = (await booking.getHistory(
        filter: const HistoryFilter(kinds: {HistoryKind.milestone}),
        ventureId: venture.id,
      )).getOrThrow();
      expect(onlyMilestones.map((e) => e.kind).toSet(), {
        HistoryKind.milestone,
      });
      final two = (await booking.getHistory(
        filter: const HistoryFilter(
          kinds: {HistoryKind.milestone, HistoryKind.stage},
        ),
        ventureId: venture.id,
      )).getOrThrow();
      expect(two.map((e) => e.kind).toSet(), {
        HistoryKind.milestone,
        HistoryKind.stage,
      });
      // Un periodo en el pasado lejano no trae nada.
      expect(
        (await booking.getHistory(
          filter: HistoryFilter(
            from: DateTime(2000, 1, 1),
            to: DateTime(2000, 1, 31),
          ),
          ventureId: venture.id,
        )).getOrThrow(),
        isEmpty,
      );

      // CU24: reportar, listar y no repetir una necesidad abierta.
      final needs = NeedsRepositoryImpl(NeedsRemoteDataSource(dio));
      final categories = (await needs.getCategories()).getOrThrow();
      expect(
        categories,
        isNotEmpty,
        reason: 'El backend necesita rubros (corre el seed)',
      );
      final reported = (await needs.report(
        ventureId: venture.id,
        categoryId: categories.first.id,
        kind: NeedKind.difficulty,
        priority: NeedPriority.high,
        description: 'No llego a mis primeros clientes',
      )).getOrThrow();
      expect(reported.kind, NeedKind.difficulty);
      expect(reported.priority, NeedPriority.high);
      expect(reported.resolved, isFalse);
      expect(reported.description, 'No llego a mis primeros clientes');
      expect(
        (await needs.getNeeds(venture.id)).getOrThrow().single.id,
        reported.id,
      );
      final duplicate = await needs.report(
        ventureId: venture.id,
        categoryId: categories.first.id,
        kind: NeedKind.need,
        priority: NeedPriority.low,
        description: 'Otra vez',
      );
      expect(duplicate.failureOrNull, isA<NeedAlreadyRegisteredFailure>());

      // CU23: una sesión que no existe se informa, no revienta.
      expect((await booking.getSession(999999)).failureOrNull, isNotNull);

      // CU11: sin haber hablado con el coach no hay conversaciones.
      final assistant = AssistantRepositoryImpl(AssistantRemoteDataSource(dio));
      expect((await assistant.getConversations()).getOrThrow(), isEmpty);
    },
  );
}
