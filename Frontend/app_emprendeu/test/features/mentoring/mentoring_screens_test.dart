import 'package:app_emprendeu/features/mentoring/domain/entities/booking_status.dart';
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
    // vuelve a la lista, con el aviso y la sesión nueva
    expect(find.textContaining('Mentoría agendada'), findsOneWidget);
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
}
