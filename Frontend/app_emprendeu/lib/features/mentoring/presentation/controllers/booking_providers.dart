import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/booking_status.dart';
import '../../domain/entities/history_event.dart';
import '../../domain/entities/mentor.dart';
import '../../domain/entities/mentoring_session.dart';
import '../../domain/entities/time_slot.dart';
import '../../domain/repositories/booking_repository.dart';
import '../../domain/usecases/booking_usecases.dart';

/// Contrato del repositorio de agenda; la implementación se inyecta en `app/providers.dart`.
final bookingRepositoryProvider = Provider<BookingRepository>(
  (ref) =>
      throw UnimplementedError('bookingRepositoryProvider sin implementación'),
);

final getBookingStatusUseCaseProvider = Provider(
  (ref) => GetBookingStatusUseCase(ref.watch(bookingRepositoryProvider)),
);
final getMentorsUseCaseProvider = Provider(
  (ref) => GetMentorsUseCase(ref.watch(bookingRepositoryProvider)),
);
final getSlotsUseCaseProvider = Provider(
  (ref) => GetSlotsUseCase(ref.watch(bookingRepositoryProvider)),
);
final getMySessionsUseCaseProvider = Provider(
  (ref) => GetMySessionsUseCase(ref.watch(bookingRepositoryProvider)),
);
final getHistoryUseCaseProvider = Provider(
  (ref) => GetHistoryUseCase(ref.watch(bookingRepositoryProvider)),
);
final bookSessionUseCaseProvider = Provider(
  (ref) => BookSessionUseCase(ref.watch(bookingRepositoryProvider)),
);

/// Qué sesiones se muestran: estado y, opcionalmente, un periodo (días inclusive).
typedef SessionsQuery = ({SessionFilter filter, DateTime? from, DateTime? to});

/// Turnos de un asesor en un día.
typedef SlotsQuery = ({int mentorId, DateTime day});

final bookingStatusProvider = FutureProvider.autoDispose<BookingStatus>(
  (ref) async =>
      (await ref.watch(getBookingStatusUseCaseProvider)()).getOrThrow(),
);

final mentorsProvider = FutureProvider.autoDispose<List<Mentor>>(
  (ref) async => (await ref.watch(getMentorsUseCaseProvider)()).getOrThrow(),
);

final slotsProvider = FutureProvider.autoDispose
    .family<List<TimeSlot>, SlotsQuery>(
      (ref, query) async => (await ref.watch(getSlotsUseCaseProvider)(
        query.mentorId,
        query.day,
      )).getOrThrow(),
    );

final mySessionsProvider = FutureProvider.autoDispose
    .family<List<MentoringSession>, SessionsQuery>(
      (ref, query) async => (await ref.watch(getMySessionsUseCaseProvider)(
        query.filter,
        from: query.from,
        to: query.to,
      )).getOrThrow(),
    );

/// Historial del emprendimiento; `true` = más reciente primero.
final historyProvider = FutureProvider.autoDispose
    .family<List<HistoryEvent>, bool>(
      (ref, newestFirst) async =>
          (await ref.watch(getHistoryUseCaseProvider)(newestFirst: newestFirst))
              .getOrThrow(),
    );

/// Agendar una mentoría. Devuelve `null` si salió bien o el [Failure] para mostrarlo.
class BookingController extends Notifier<void> {
  @override
  void build() {}

  Future<Failure?> book({
    required Mentor mentor,
    required DateTime day,
    required TimeSlot slot,
    String? topic,
  }) async {
    final result = await ref.read(bookSessionUseCaseProvider)(
      mentorId: mentor.id,
      day: day,
      slot: slot,
      topic: topic,
    );
    switch (result) {
      case Ok():
        ref.invalidate(mySessionsProvider);
        ref.invalidate(slotsProvider);
        return null;
      case Err(:final failure):
        // El horario se ocupó: que la lista de turnos se vuelva a pedir.
        if (failure is SlotUnavailableFailure) ref.invalidate(slotsProvider);
        return failure;
    }
  }
}

final bookingControllerProvider = NotifierProvider<BookingController, void>(
  BookingController.new,
);
