// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NotificationDto _$NotificationDtoFromJson(Map<String, dynamic> json) =>
    _NotificationDto(
      notificacionId: (json['notificacion_id'] as num).toInt(),
      tipo: json['tipo'] as String,
      titulo: json['titulo'] as String,
      cuerpo: json['cuerpo'] as String,
      ruta: json['ruta'] as String?,
      leida: json['leida'] as bool,
      creadaEn: DateTime.parse(json['creada_en'] as String),
    );

Map<String, dynamic> _$NotificationDtoToJson(_NotificationDto instance) =>
    <String, dynamic>{
      'notificacion_id': instance.notificacionId,
      'tipo': instance.tipo,
      'titulo': instance.titulo,
      'cuerpo': instance.cuerpo,
      'ruta': instance.ruta,
      'leida': instance.leida,
      'creada_en': instance.creadaEn.toIso8601String(),
    };
