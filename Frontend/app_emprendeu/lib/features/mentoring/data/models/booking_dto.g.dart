// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MentorDto _$MentorDtoFromJson(Map<String, dynamic> json) => _MentorDto(
  usuarioId: (json['usuario_id'] as num).toInt(),
  nombre: json['nombre'] as String,
  especialidad: json['especialidad'] as String?,
  bloqueado: json['bloqueado'] as bool? ?? false,
  motivoBloqueo: json['motivo_bloqueo'] as String?,
);

Map<String, dynamic> _$MentorDtoToJson(_MentorDto instance) =>
    <String, dynamic>{
      'usuario_id': instance.usuarioId,
      'nombre': instance.nombre,
      'especialidad': instance.especialidad,
      'bloqueado': instance.bloqueado,
      'motivo_bloqueo': instance.motivoBloqueo,
    };

_SlotDto _$SlotDtoFromJson(Map<String, dynamic> json) => _SlotDto(
  inicio: DateTime.parse(json['inicio'] as String),
  hora: json['hora'] as String,
  disponible: json['disponible'] as bool,
);

Map<String, dynamic> _$SlotDtoToJson(_SlotDto instance) => <String, dynamic>{
  'inicio': instance.inicio.toIso8601String(),
  'hora': instance.hora,
  'disponible': instance.disponible,
};

_BookingStatusDto _$BookingStatusDtoFromJson(Map<String, dynamic> json) =>
    _BookingStatusDto(
      habilitado: json['habilitado'] as bool,
      motivo: json['motivo'] as String?,
      etapa: json['etapa'] as String?,
    );

Map<String, dynamic> _$BookingStatusDtoToJson(_BookingStatusDto instance) =>
    <String, dynamic>{
      'habilitado': instance.habilitado,
      'motivo': instance.motivo,
      'etapa': instance.etapa,
    };

_MentoringSessionDto _$MentoringSessionDtoFromJson(Map<String, dynamic> json) =>
    _MentoringSessionDto(
      sesionId: (json['sesion_id'] as num).toInt(),
      estado: json['estado'] as String?,
      tema: json['tema'] as String?,
      modalidad: json['modalidad'] as String?,
      mentor: json['mentor'] as String?,
      especialidad: json['especialidad'] as String?,
      emprendimiento: json['emprendimiento'] as String?,
      fechaProgramada: json['fecha_programada'] == null
          ? null
          : DateTime.parse(json['fecha_programada'] as String),
      fechaRealizada: json['fecha_realizada'] == null
          ? null
          : DateTime.parse(json['fecha_realizada'] as String),
      observaciones: json['observaciones'] as String?,
      totalRecomendaciones:
          (json['total_recomendaciones'] as num?)?.toInt() ?? 0,
      totalCompromisos: (json['total_compromisos'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$MentoringSessionDtoToJson(
  _MentoringSessionDto instance,
) => <String, dynamic>{
  'sesion_id': instance.sesionId,
  'estado': instance.estado,
  'tema': instance.tema,
  'modalidad': instance.modalidad,
  'mentor': instance.mentor,
  'especialidad': instance.especialidad,
  'emprendimiento': instance.emprendimiento,
  'fecha_programada': instance.fechaProgramada?.toIso8601String(),
  'fecha_realizada': instance.fechaRealizada?.toIso8601String(),
  'observaciones': instance.observaciones,
  'total_recomendaciones': instance.totalRecomendaciones,
  'total_compromisos': instance.totalCompromisos,
};
