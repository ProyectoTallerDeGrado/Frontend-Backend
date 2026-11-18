import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../ventures/index.dart';
import '../../domain/entities/booking_status.dart';
import '../../domain/entities/history_event.dart';
import '../../domain/entities/history_filter.dart';
import '../../domain/entities/mentor.dart';
import '../../domain/entities/mentoring_session.dart';
import '../../domain/entities/task.dart';
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
final getSessionUseCaseProvider = Provider(
  (ref) => GetSessionUseCase(ref.watch(bookingRepositoryProvider)),
);
final cancelSessionUseCaseProvider = Provider(
  (ref) => CancelSessionUseCase(ref.watch(bookingRepositoryProvider)),
);
final getTasksUseCaseProvider = Provider(
  (ref) => GetTasksUseCase(ref.watch(bookingRepositoryProvider)),
);
final bookSessionUseCaseProvider = Provider(
  (ref) => BookSessionUseCase(ref.watch(bookingRepositoryProvider)),
);

/// Qué sesiones se muestran: estado y, opcionalmente, un periodo (días inclusive).
typedef SessionsQuery = ({SessionFilter filter, DateTime? from, DateTime? to});

/// Turnos de un asesor en un día.
typedef SlotsQuery = ({int mentorId, DateTime day});

/// Si el emprendimiento activo ya puede agendar (depende de su etapa y retos).
final bookingStatusProvider = FutureProvider.autoDispose<BookingStatus>((
  ref,
) async {
  final ventureId = await ref.watch(currentVentureIdProvider.future);
  return (await ref.watch(getBookingStatusUseCaseProvider)(
    ventureId: ventureId,
  )).getOrThrow();
});

/// Asesores asignados al emprendimiento activo.
final mentorsProvider = FutureProvider.autoDispose<List<Mentor>>((ref) async {
  final ventureId = await ref.watch(currentVentureIdProvider.future);
  return (await ref.watch(getMentorsUseCaseProvider)(ventureId: ventureId))
      .getOrThrow();
});

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

/// Historial del emprendimiento activo según orden, tipos y periodo.
final historyProvider = FutureProvider.autoDispose
    .family<List<HistoryEvent>, HistoryFilter>((ref, filter) async {
      final ventureId = await ref.watch(currentVentureIdProvider.future);
      return (await ref.watch(getHistoryUseCaseProvider)(
        filter: filter,
        ventureId: ventureId,
      )).getOrThrow();
    });

/// Detalle de una mentoría (CU23).
final sessionDetailProvider = FutureProvider.autoDispose
    .family<MentoringSession, int>(
      (ref, id) async =>
          (await ref.watch(getSessionUseCaseProvider)(id)).getOrThrow(),
    );

/// Compromisos e hitos del emprendedor (CU22; requiere conexión).
final tasksProvider = FutureProvider.autoDispose.family<List<Task>, TaskFilter>(
  (ref, filter) async =>
      (await ref.watch(getTasksUseCaseProvider)(filter)).getOrThrow(),
);

/// Agendar una mentoría. Devuelve `null` si salió bien o el [Failure] para mostrarlo.
class BookingController extends Notifier<void> {
  @override
  void build() {}

  /// Cancela una mentoría programada. `null` si salió bien o el [Failure] para mostrarlo.
  Future<Failure?> cancel(int sessionId) async {
    final result = await ref.read(cancelSessionUseCaseProvider)(sessionId);
    // Salió bien o ya no estaba programada: en ambos casos la pantalla debe refrescarse.
    switch (result) {
      case Ok():
        ref.invalidate(mySessionsProvider);
        ref.invalidate(sessionDetailProvider);
        ref.invalidate(slotsProvider);
        return null;
      case Err(:final failure):
        if (failure is SessionClosedFailure) {
          ref.invalidate(mySessionsProvider);
          ref.invalidate(sessionDetailProvider);
        }
        return failure;
    }
    return null;
  }

  Future<Failure?> book({
    required Mentor mentor,
    required DateTime day,
    required TimeSlot slot,
    String? topic,
  }) async {
    final ventureId = await ref.read(currentVentureIdProvider.future);
    final result = await ref.read(bookSessionUseCaseProvider)(
      mentorId: mentor.id,
      day: day,
      slot: slot,
      topic: topic,
      ventureId: ventureId,
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
    return null;
  }
}

final bookingControllerProvider = NotifierProvider<BookingController, void>(
  BookingController.new,
);
