import 'package:app_emprendeu/core/error/failure.dart';
import 'package:app_emprendeu/core/error/result.dart';
import 'package:app_emprendeu/features/mentoring/domain/entities/mentoring_session.dart';
import 'package:app_emprendeu/features/mentoring/domain/entities/time_slot.dart';
import 'package:app_emprendeu/features/mentoring/domain/usecases/booking_usecases.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fake_booking_repository.dart';

TimeSlot get _slot =>
    TimeSlot(start: tomorrow9, label: '09:00', available: true);

void main() {
  final day = DateTime(2030, 1, 15);

  group('BookSessionUseCase', () {
    test('agenda cuando el horario sigue libre y limpia el tema', () async {
      final repo = FakeBookingRepository();
      final result = await BookSessionUseCase(repo)(
        mentorId: 11,
        day: day,
        slot: _slot,
        topic: '  Costos  ',
      );
      expect(result, isA<Ok<MentoringSession>>());
      expect(repo.bookCalls, 1);
      expect(repo.lastTopic, 'Costos');
    });

    test('un tema vacío no se envía', () async {
      final repo = FakeBookingRepository();
      await BookSessionUseCase(repo)(
        mentorId: 11,
        day: day,
        slot: _slot,
        topic: '   ',
      );
      expect(repo.lastTopic, isNull);
    });

    test('vuelve a verificar el horario: si se ocupó, no agenda', () async {
      // El horario se ocupa justo después de mostrarse (primera lectura).
      final repo = FakeBookingRepository(takeOnRead: 1);
      final result = await BookSessionUseCase(repo)(
        mentorId: 11,
        day: day,
        slot: _slot,
      );
      expect(result.failureOrNull, isA<SlotUnavailableFailure>());
      expect(repo.bookCalls, 0, reason: 'ni siquiera intenta agendar');
    });
  });
}
