import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/app_notification.dart';

part 'notification_dto.freezed.dart';
part 'notification_dto.g.dart';

@freezed
abstract class NotificationDto with _$NotificationDto {
  const NotificationDto._();

  const factory NotificationDto({
    @JsonKey(name: 'notificacion_id') required int notificacionId,
    required String tipo,
    required String titulo,
    required String cuerpo,
    String? ruta,
    required bool leida,
    @JsonKey(name: 'creada_en') required DateTime creadaEn,
  }) = _NotificationDto;

  factory NotificationDto.fromJson(Map<String, dynamic> json) =>
      _$NotificationDtoFromJson(json);

  AppNotification toEntity() => AppNotification(
    id: notificacionId,
    kind: tipo,
    title: titulo,
    body: cuerpo,
    route: ruta,
    read: leida,
    createdAt: creadaEn.toLocal(),
  );
}
