import 'package:app_emprendeu/core/error/failure.dart';
import 'package:app_emprendeu/core/error/result.dart';
import 'package:app_emprendeu/features/mentoring/data/datasources/mentoring_local_data_source.dart';
import 'package:app_emprendeu/features/mentoring/data/datasources/mentoring_remote_data_source.dart';
import 'package:app_emprendeu/features/mentoring/data/models/mentoring_dto.dart';
import 'package:app_emprendeu/features/mentoring/data/models/pending_op.dart';
import 'package:app_emprendeu/features/mentoring/data/repositories/mentoring_repository_impl.dart';
import 'package:app_emprendeu/features/mentoring/domain/entities/commitment.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../support/fakes.dart';

class _MockRemote extends Mock implements MentoringRemoteDataSource {}

DioException get _offline => DioException(
  requestOptions: RequestOptions(path: '/x'),
  type: DioExceptionType.connectionError,
);

const _commitment = Commitment(
  id: 5,
  sessionId: 1,
  description: 'Subir fotos',
  done: false,
);

void main() {
  late _MockRemote remote;
  late InMemoryKeyValueStore store;
  late MentoringRepositoryImpl repo;

  setUpAll(() => registerFallbackValue(<PendingOp>[]));

  setUp(() {
    remote = _MockRemote();
    store = InMemoryKeyValueStore();
    repo = MentoringRepositoryImpl(remote, MentoringLocalDataSource(store));
  });

  test('sin conexión un compromiso queda pendiente y se ve marcado', () async {
    when(() => remote.setCommitmentDone(any(), any())).thenThrow(_offline);

    final result = await repo.setCommitmentDone(_commitment, true);

    final saved = (result as Ok<Commitment>).value;
    expect(saved.done, isTrue);
    expect(saved.pendingSync, isTrue);
    expect(await repo.pendingCount(), 1);
  });

  test(
    'marcar y desmarcar offline deja un solo cambio (gana el último)',
    () async {
      when(() => remote.setCommitmentDone(any(), any())).thenThrow(_offline);

      await repo.setCommitmentDone(_commitment, true);
      await repo.setCommitmentDone(_commitment.copyWith(done: true), false);

      expect(await repo.pendingCount(), 1);
      final ops = await MentoringLocalDataSource(store).readOps();
      expect((ops.single as PendingCommitmentOp).done, isFalse);
    },
  );

  test('un error del servidor no se encola', () async {
    when(() => remote.setCommitmentDone(any(), any())).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/x'),
        response: Response(
          requestOptions: RequestOptions(path: '/x'),
          statusCode: 403,
          data: {
            'error': {'code': 'forbidden', 'message': 'No', 'details': null},
          },
        ),
        type: DioExceptionType.badResponse,
      ),
    );

    final result = await repo.setCommitmentDone(_commitment, true);

    expect(result, isA<Err<Commitment>>());
    expect(await repo.pendingCount(), 0);
  });

  test(
    'un avance sin conexión se guarda con su referencia y aparece primero',
    () async {
      when(() => remote.logProgress(any(), any())).thenThrow(_offline);
      when(() => remote.progress()).thenThrow(_offline);

      final created = (await repo.logProgress('Hablé con 3 clientes')) as Ok;
      expect((created.value as dynamic).pendingSync, isTrue);
      expect(await repo.pendingCount(), 1);

      // Sin red y sin copia previa no se puede listar, pero lo pendiente se conserva.
      final list = await repo.getProgressLogs();
      expect(list, isA<Err>());
      expect(await repo.pendingCount(), 1);
    },
  );

  test(
    'la lista sin conexión usa la última copia y aplica lo pendiente',
    () async {
      when(() => remote.commitments()).thenAnswer(
        (_) async => [
          const CommitmentDto(
            compromisoId: 5,
            sesionId: 1,
            descripcion: 'Subir fotos',
            estado: 'pendiente',
          ),
        ],
      );
      expect(
        ((await repo.getCommitments()) as Ok<List<Commitment>>)
            .value
            .single
            .done,
        isFalse,
      );

      when(() => remote.setCommitmentDone(any(), any())).thenThrow(_offline);
      await repo.setCommitmentDone(_commitment, true);
      when(() => remote.commitments()).thenThrow(_offline);

      final offline = (await repo.getCommitments()) as Ok<List<Commitment>>;
      expect(offline.value.single.done, isTrue);
      expect(offline.value.single.pendingSync, isTrue);
    },
  );

  test('sincronizar envía todo en un lote y vacía la cola', () async {
    when(() => remote.setCommitmentDone(any(), any())).thenThrow(_offline);
    when(() => remote.logProgress(any(), any())).thenThrow(_offline);
    await repo.setCommitmentDone(_commitment, true);
    await repo.logProgress('Avance');
    when(() => remote.sync(any())).thenAnswer(
      (_) async => const SyncResultDto(
        avances: [
          ProgressDto(
            seguimientoId: 9,
            observaciones: 'Avance',
            referenciaCliente: 'x',
          ),
        ],
        compromisos: [
          CommitmentDto(
            compromisoId: 5,
            sesionId: 1,
            descripcion: 'Subir fotos',
            estado: 'cumplido',
          ),
        ],
        errores: ['compromiso 99: no existe'],
      ),
    );

    final result = (await repo.syncPending()) as Ok;

    final summary = result.value as dynamic;
    expect(summary.synced, 2);
    expect(summary.errors, hasLength(1));
    expect(await repo.pendingCount(), 0);
    final sent =
        verify(() => remote.sync(captureAny())).captured.single
            as List<PendingOp>;
    expect(sent, hasLength(2));
  });

  test('si sincronizar falla por red, la cola se conserva', () async {
    when(() => remote.setCommitmentDone(any(), any())).thenThrow(_offline);
    await repo.setCommitmentDone(_commitment, true);
    when(() => remote.sync(any())).thenThrow(_offline);

    final result = await repo.syncPending();

    expect(result.failureOrNull, isA<NetworkFailure>());
    expect(await repo.pendingCount(), 1);
  });
}
