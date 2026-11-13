import 'dart:convert';
import 'dart:typed_data';

import 'package:app_emprendeu/features/mentoring/data/datasources/booking_remote_data_source.dart';
import 'package:app_emprendeu/features/mentoring/domain/entities/history_event.dart';
import 'package:app_emprendeu/features/mentoring/domain/entities/history_filter.dart';
import 'package:app_emprendeu/features/mentoring/domain/entities/task.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guarda la última petición y responde con [body].
class _CapturingAdapter implements HttpClientAdapter {
  _CapturingAdapter(this.body);

  final Object body;
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

(BookingRemoteDataSource, _CapturingAdapter) _build(Object body) {
  final adapter = _CapturingAdapter(body);
  final dio = Dio(BaseOptions(baseUrl: 'http://api.test/api/v1'))
    ..httpClientAdapter = adapter;
  return (BookingRemoteDataSource(dio), adapter);
}

void main() {
  test(
    'el historial envía cada tipo como tipo=a&tipo=b (no tipo[]=a)',
    () async {
      final (remote, adapter) = _build(<Object>[]);
      await remote.history(
        filter: HistoryFilter(
          newestFirst: false,
          kinds: {HistoryKind.session, HistoryKind.milestone},
          from: DateTime(2030, 1, 5),
          to: DateTime(2030, 1, 20),
        ),
      );
      final uri = adapter.last!.uri;
      expect(uri.path, '/api/v1/mentoring/ventures/me/history');
      expect(uri.queryParametersAll['tipo'], ['sesion', 'hito']);
      expect(uri.query, isNot(contains('%5B%5D')));
      expect(uri.queryParameters['orden'], 'asc');
      expect(uri.queryParameters['desde'], '2030-01-05');
      expect(uri.queryParameters['hasta'], '2030-01-20');
    },
  );

  test('sin filtros el historial no manda tipo ni fechas', () async {
    final (remote, adapter) = _build(<Object>[]);
    await remote.history(filter: const HistoryFilter(), ventureId: 4);
    final uri = adapter.last!.uri;
    expect(uri.path, '/api/v1/mentoring/ventures/4/history');
    expect(uri.queryParameters.keys, ['orden']);
  });

  test('las tareas piden tipo, estado y periodo', () async {
    final (remote, adapter) = _build(<Object>[]);
    await remote.tasks(
      TaskFilter(
        kind: TaskKind.milestone,
        state: TaskState.done,
        from: DateTime(2030, 2, 1),
        to: DateTime(2030, 2, 10),
      ),
    );
    final q = adapter.last!.uri.queryParameters;
    expect(adapter.last!.uri.path, '/api/v1/mentoring/tasks/me');
    expect(q, {
      'tipo': 'hito',
      'estado': 'cumplido',
      'desde': '2030-02-01',
      'hasta': '2030-02-10',
    });
  });

  test('una tarea del backend se convierte en entidad', () async {
    final (remote, _) = _build([
      {
        'tipo': 'compromiso',
        'referencia_id': 3,
        'emprendimiento_id': 1,
        'titulo': 'Entrevistar 5 clientes',
        'detalle': null,
        'responsable': 'Camila',
        'estado': 'pendiente',
        'fecha_prevista': '2030-01-10T12:00:00Z',
        'vencida': true,
      },
    ]);
    final task = (await remote.tasks(const TaskFilter())).single.toEntity();
    expect(task.kind, TaskKind.commitment);
    expect(task.state, TaskState.pending);
    expect(task.overdue, isTrue);
    expect(task.dueAt, DateTime.utc(2030, 1, 10, 12));
  });

  test('cancelar usa POST /sessions/{id}/cancel', () async {
    final (remote, adapter) = _build({'sesion_id': 9, 'estado': 'cancelada'});
    final dto = await remote.cancel(9);
    expect(adapter.last!.method, 'POST');
    expect(adapter.last!.uri.path, '/api/v1/mentoring/sessions/9/cancel');
    expect(dto.toEntity().id, 9);
  });

  test('HistoryFilter y TaskFilter tienen igualdad por valor', () {
    expect(
      const HistoryFilter(kinds: {HistoryKind.stage}),
      HistoryFilter(kinds: {HistoryKind.stage}),
    );
    expect(
      const HistoryFilter(kinds: {HistoryKind.stage}).hashCode,
      HistoryFilter(kinds: {HistoryKind.stage}).hashCode,
    );
    expect(
      const HistoryFilter(kinds: {HistoryKind.stage}) ==
          const HistoryFilter(kinds: {HistoryKind.session}),
      isFalse,
    );
    expect(const TaskFilter(), const TaskFilter());
  });
}
