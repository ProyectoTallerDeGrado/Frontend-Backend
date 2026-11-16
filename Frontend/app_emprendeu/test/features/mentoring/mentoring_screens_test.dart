import 'package:app_emprendeu/core/error/failure.dart';
import 'package:app_emprendeu/features/mentoring/domain/entities/booking_status.dart';
import 'package:app_emprendeu/features/mentoring/domain/entities/history_event.dart';
import 'package:app_emprendeu/features/mentoring/domain/entities/task.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';
import '../auth/fake_auth_repository.dart';
import 'fake_booking_repository.dart';

Future<void> _openMentorias(
  WidgetTester tester,
  FakeBookingRepository booking,
) async {
  await pumpApp(
    tester,
    TestWorld(
      auth: FakeAuthRepository(token: 'tok-1'),
      booking: booking,
    ),
  );
  await tester.tap(find.text('Mentorías'));
  await settle(tester);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 200));
  await tester.tap(finder);
  await settle(tester);
}

final _bookButton = find.widgetWithText(FilledButton, 'Agendar mentoría');

void main() {
  testWidgets('muestra las próximas y cambia de estado con los filtros', (
    tester,
  ) async {
    await _openMentorias(tester, FakeBookingRepository());
    expect(find.text('Costos'), findsOneWidget);
    expect(find.text('Programada'), findsOneWidget);
    expect(find.text('Propuesta de valor'), findsNothing);

    await _tap(tester, find.text('Realizadas'));
    expect(find.text('Propuesta de valor'), findsOneWidget);
    expect(find.text('Realizada'), findsOneWidget);
    expect(find.text('2 recomendaciones · 1 compromiso'), findsOneWidget);
    expect(find.text('Costos'), findsNothing);

    await _tap(tester, find.text('Canceladas'));
    expect(find.text('No tienes mentorías canceladas.'), findsOneWidget);
  });

  testWidgets('sin etapa habilitada no se puede agendar y se explica por qué', (
    tester,
  ) async {
    await _openMentorias(
      tester,
      FakeBookingRepository(
        status: const BookingStatus(
          enabled: false,
          reason: 'Avanza hasta Incubación para habilitar el agendamiento.',
        ),
      ),
    );
    expect(
      find.text('Avanza hasta Incubación para habilitar el agendamiento.'),
      findsOneWidget,
    );
    expect(tester.widget<FilledButton>(_bookButton).onPressed, isNull);
  });

  testWidgets('agenda: asesor, horario y confirmar', (tester) async {
    final booking = FakeBookingRepository();
    await _openMentorias(tester, booking);

    await _tap(tester, _bookButton);
    await _tap(tester, find.text('Marcelo Cuellar'));
    await _tap(tester, find.text('09:00'));
    await tester.enterText(find.byType(TextField), 'Precios');
    await _tap(tester, find.text('Confirmar mentoría'));

    expect(booking.bookCalls, 1);
    expect(booking.lastTopic, 'Precios');
    // confirma a pantalla completa y, al seguir, vuelve a la lista con la sesión nueva
    expect(find.text('Mentoría agendada'), findsOneWidget);
    await _tap(tester, find.text('Ver mis mentorías'));
    expect(find.text('Precios'), findsOneWidget);
  });

  testWidgets('si el horario se ocupa antes de confirmar, avisa y no agenda', (
    tester,
  ) async {
    // Se ocupa al segundo pedido de turnos: justo al confirmar.
    final booking = FakeBookingRepository(takeOnRead: 2);
    await _openMentorias(tester, booking);

    await _tap(tester, _bookButton);
    await _tap(tester, find.text('Marcelo Cuellar'));
    await _tap(tester, find.text('09:00'));
    await _tap(tester, find.text('Confirmar mentoría'));

    expect(booking.bookCalls, 0);
    expect(
      find.text('Ese horario ya no está disponible. Elige otro.'),
      findsOneWidget,
    );
    // sigue en la pantalla de agendar y el botón queda desactivado hasta elegir otro
    expect(find.text('3. Elige el horario'), findsOneWidget);
    final confirm = find.widgetWithText(FilledButton, 'Confirmar mentoría');
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);
  });

  testWidgets('el historial muestra la línea de tiempo y cambia de orden', (
    tester,
  ) async {
    final booking = FakeBookingRepository();
    await _openMentorias(tester, booking);

    await _tap(tester, find.text('Ver historial del emprendimiento'));
    expect(booking.lastNewestFirst, true);
    expect(find.text('Costos'), findsOneWidget);
    expect(find.text('Primer prototipo'), findsOneWidget);
    expect(find.textContaining('por Marcelo Cuellar'), findsOneWidget);

    await _tap(tester, find.text('Cronológico'));
    expect(booking.lastNewestFirst, false);
  });

  testWidgets('historial vacío explica que aún no hay actividad', (
    tester,
  ) async {
    final booking = FakeBookingRepository()..history = [];
    await _openMentorias(tester, booking);
    await _tap(tester, find.text('Ver historial del emprendimiento'));
    expect(find.textContaining('Todavía no hay actividad'), findsOneWidget);
  });

  testWidgets('sin asesor asignado se explica qué pasa', (tester) async {
    await _openMentorias(tester, FakeBookingRepository(mentors: []));
    await _tap(tester, _bookButton);
    expect(
      find.textContaining('Todavía no tienes un asesor asignado'),
      findsOneWidget,
    );
    expect(find.text('2. Elige el día'), findsNothing);
  });

  testWidgets('CU23: abre el detalle y cancela una mentoría programada', (
    tester,
  ) async {
    final booking = FakeBookingRepository();
    await _openMentorias(tester, booking);

    await _tap(tester, find.text('Costos'));
    expect(find.text('Cancelar mentoría'), findsOneWidget);
    await _tap(tester, find.text('Cancelar mentoría'));
    // pide confirmación antes de cancelar
    expect(find.text('¿Cancelar la mentoría?'), findsOneWidget);
    expect(booking.cancelCalls, 0);
    await _tap(tester, find.widgetWithText(FilledButton, 'Cancelar mentoría'));

    expect(booking.cancelCalls, 1);
    expect(find.text('Mentoría cancelada.'), findsOneWidget);
    // el detalle ya no ofrece cancelar de nuevo
    expect(find.text('Cancelar mentoría'), findsNothing);
    expect(find.text('Cancelada'), findsOneWidget);
  });

  testWidgets('CU23: volver en el diálogo no cancela nada', (tester) async {
    final booking = FakeBookingRepository();
    await _openMentorias(tester, booking);
    await _tap(tester, find.text('Costos'));
    await _tap(tester, find.text('Cancelar mentoría'));
    await _tap(tester, find.text('Volver'));
    expect(booking.cancelCalls, 0);
    expect(find.text('Cancelar mentoría'), findsOneWidget);
  });

  testWidgets('CU23: si la mentoría ya no se puede cancelar, lo explica', (
    tester,
  ) async {
    final booking = FakeBookingRepository()
      ..cancelFailure = const SessionClosedFailure();
    await _openMentorias(tester, booking);
    await _tap(tester, find.text('Costos'));
    await _tap(tester, find.text('Cancelar mentoría'));
    await _tap(tester, find.widgetWithText(FilledButton, 'Cancelar mentoría'));
    expect(find.text('Esta mentoría ya no se puede cancelar.'), findsOneWidget);
  });

  testWidgets('CU23: una mentoría realizada no se puede cancelar', (
    tester,
  ) async {
    await _openMentorias(tester, FakeBookingRepository());
    await _tap(tester, find.text('Realizadas'));
    await _tap(tester, find.text('Propuesta de valor'));
    expect(find.text('Cancelar mentoría'), findsNothing);
  });

  testWidgets('CU19: el historial se filtra por tipo y se quitan los filtros', (
    tester,
  ) async {
    final booking = FakeBookingRepository();
    await _openMentorias(tester, booking);
    await _tap(tester, find.text('Ver historial del emprendimiento'));
    expect(find.text('Costos'), findsOneWidget);

    await _tap(tester, find.widgetWithText(FilterChip, 'Hito'));
    expect(booking.lastFilter!.kinds, {HistoryKind.milestone});
    expect(find.text('Primer prototipo'), findsOneWidget);
    expect(find.text('Costos'), findsNothing);

    await _tap(tester, find.text('Quitar filtros'));
    expect(booking.lastFilter!.kinds, isEmpty);
    expect(find.text('Costos'), findsOneWidget);
  });

  testWidgets('CU19: sin eventos con el filtro, lo dice', (tester) async {
    await _openMentorias(tester, FakeBookingRepository());
    await _tap(tester, find.text('Ver historial del emprendimiento'));
    await _tap(tester, find.widgetWithText(FilterChip, 'Etapa'));
    expect(find.text('No hay eventos con esos filtros.'), findsOneWidget);
  });

  testWidgets('CU22: tareas pendientes con filtros de tipo y estado', (
    tester,
  ) async {
    final booking = FakeBookingRepository();
    await _openMentorias(tester, booking);

    await _tap(tester, find.text('Tareas y compromisos'));
    expect(find.text('Entrevistar 5 clientes'), findsOneWidget);
    expect(find.text('Enviar cotización'), findsOneWidget);
    expect(find.text('Primer prototipo'), findsOneWidget);
    expect(find.text('Vencido'), findsOneWidget);
    expect(find.text('Registro de marca'), findsNothing);

    await _tap(tester, find.widgetWithText(ChoiceChip, 'Hitos'));
    expect(booking.lastTaskFilter!.kind, TaskKind.milestone);
    expect(find.text('Primer prototipo'), findsOneWidget);
    expect(find.text('Entrevistar 5 clientes'), findsNothing);

    await _tap(tester, find.widgetWithText(ChoiceChip, 'Cumplidas'));
    expect(booking.lastTaskFilter!.state, TaskState.done);
    expect(find.text('Registro de marca'), findsOneWidget);
    expect(find.text('Cumplido'), findsOneWidget);
  });

  testWidgets('CU22: sin tareas pendientes lo celebra', (tester) async {
    final booking = FakeBookingRepository()..tasks = [];
    await _openMentorias(tester, booking);
    await _tap(tester, find.text('Tareas y compromisos'));
    expect(find.textContaining('No tienes tareas pendientes'), findsOneWidget);
  });
}
