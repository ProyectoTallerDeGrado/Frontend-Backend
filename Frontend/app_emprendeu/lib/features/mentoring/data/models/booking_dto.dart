import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/booking_status.dart';
import '../../domain/entities/mentor.dart';
import '../../domain/entities/mentoring_session.dart';
import '../../domain/entities/time_slot.dart';

part 'booking_dto.freezed.dart';
part 'booking_dto.g.dart';

@freezed
abstract class MentorDto with _$MentorDto {
  const MentorDto._();

  const factory MentorDto({
    @JsonKey(name: 'usuario_id') required int usuarioId,
    required String nombre,
    String? especialidad,
    @Default(false) bool bloqueado,
    @JsonKey(name: 'motivo_bloqueo') String? motivoBloqueo,
  }) = _MentorDto;

  factory MentorDto.fromJson(Map<String, dynamic> json) =>
      _$MentorDtoFromJson(json);

  Mentor toEntity() => Mentor(
    id: usuarioId,
    name: nombre,
    specialty: especialidad,
    locked: bloqueado,
    lockReason: motivoBloqueo,
  );
}

@freezed
abstract class SlotDto with _$SlotDto {
  const SlotDto._();

  const factory SlotDto({
    required DateTime inicio,
    required String hora,
    required bool disponible,
  }) = _SlotDto;

  factory SlotDto.fromJson(Map<String, dynamic> json) =>
      _$SlotDtoFromJson(json);

  TimeSlot toEntity() =>
      TimeSlot(start: inicio, label: hora, available: disponible);
}

@freezed
abstract class BookingStatusDto with _$BookingStatusDto {
  const BookingStatusDto._();

  const factory BookingStatusDto({
    required bool habilitado,
    String? motivo,
    String? etapa,
  }) = _BookingStatusDto;

  factory BookingStatusDto.fromJson(Map<String, dynamic> json) =>
      _$BookingStatusDtoFromJson(json);

  BookingStatus toEntity() =>
      BookingStatus(enabled: habilitado, reason: motivo, stage: etapa);
}

@freezed
abstract class MentoringSessionDto with _$MentoringSessionDto {
  const MentoringSessionDto._();

  const factory MentoringSessionDto({
    @JsonKey(name: 'sesion_id') required int sesionId,
    String? estado,
    String? tema,
    String? modalidad,
    String? mentor,
    String? especialidad,
    String? emprendimiento,
    @JsonKey(name: 'fecha_programada') DateTime? fechaProgramada,
    @JsonKey(name: 'fecha_realizada') DateTime? fechaRealizada,
    String? observaciones,
    @JsonKey(name: 'total_recomendaciones')
    @Default(0)
    int totalRecomendaciones,
    @JsonKey(name: 'total_compromisos') @Default(0) int totalCompromisos,
  }) = _MentoringSessionDto;

  factory MentoringSessionDto.fromJson(Map<String, dynamic> json) =>
      _$MentoringSessionDtoFromJson(json);

  MentoringSession toEntity() => MentoringSession(
    id: sesionId,
    state: switch (estado) {
      'realizada' => SessionState.done,
      'cancelada' => SessionState.cancelled,
      _ => SessionState.scheduled,
    },
    topic: tema,
    modality: modalidad,
    mentorName: mentor,
    specialty: especialidad,
    ventureName: emprendimiento,
    scheduledAt: fechaProgramada,
    doneAt: fechaRealizada,
    notes: observaciones,
    recommendations: totalRecomendaciones,
    commitments: totalCompromisos,
  );
}
