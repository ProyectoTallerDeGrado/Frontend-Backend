// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notification_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NotificationDto {

@JsonKey(name: 'notificacion_id') int get notificacionId; String get tipo; String get titulo; String get cuerpo; String? get ruta; bool get leida;@JsonKey(name: 'creada_en') DateTime get creadaEn;
/// Create a copy of NotificationDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotificationDtoCopyWith<NotificationDto> get copyWith => _$NotificationDtoCopyWithImpl<NotificationDto>(this as NotificationDto, _$identity);

  /// Serializes this NotificationDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as NotificationDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NotificationDto&&(identical(other.notificacionId, _this.notificacionId) || other.notificacionId == _this.notificacionId)&&(identical(other.tipo, _this.tipo) || other.tipo == _this.tipo)&&(identical(other.titulo, _this.titulo) || other.titulo == _this.titulo)&&(identical(other.cuerpo, _this.cuerpo) || other.cuerpo == _this.cuerpo)&&(identical(other.ruta, _this.ruta) || other.ruta == _this.ruta)&&(identical(other.leida, _this.leida) || other.leida == _this.leida)&&(identical(other.creadaEn, _this.creadaEn) || other.creadaEn == _this.creadaEn));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as NotificationDto;
  return Object.hash(runtimeType,_this.notificacionId,_this.tipo,_this.titulo,_this.cuerpo,_this.ruta,_this.leida,_this.creadaEn);
}

@override
String toString() {
  final _this = this as NotificationDto;
  return 'NotificationDto(notificacionId: ${_this.notificacionId}, tipo: ${_this.tipo}, titulo: ${_this.titulo}, cuerpo: ${_this.cuerpo}, ruta: ${_this.ruta}, leida: ${_this.leida}, creadaEn: ${_this.creadaEn})';
}


}

/// @nodoc
abstract mixin class $NotificationDtoCopyWith<$Res>  {
  factory $NotificationDtoCopyWith(NotificationDto value, $Res Function(NotificationDto) _then) = _$NotificationDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'notificacion_id') int notificacionId, String tipo, String titulo, String cuerpo, String? ruta, bool leida,@JsonKey(name: 'creada_en') DateTime creadaEn
});




}
/// @nodoc
class _$NotificationDtoCopyWithImpl<$Res>
    implements $NotificationDtoCopyWith<$Res> {
  _$NotificationDtoCopyWithImpl(this._self, this._then);

  final NotificationDto _self;
  final $Res Function(NotificationDto) _then;

/// Create a copy of NotificationDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? notificacionId = null,Object? tipo = null,Object? titulo = null,Object? cuerpo = null,Object? ruta = freezed,Object? leida = null,Object? creadaEn = null,}) {
  return _then(NotificationDto(
notificacionId: null == notificacionId ? _self.notificacionId : notificacionId // ignore: cast_nullable_to_non_nullable
as int,tipo: null == tipo ? _self.tipo : tipo // ignore: cast_nullable_to_non_nullable
as String,titulo: null == titulo ? _self.titulo : titulo // ignore: cast_nullable_to_non_nullable
as String,cuerpo: null == cuerpo ? _self.cuerpo : cuerpo // ignore: cast_nullable_to_non_nullable
as String,ruta: freezed == ruta ? _self.ruta : ruta // ignore: cast_nullable_to_non_nullable
as String?,leida: null == leida ? _self.leida : leida // ignore: cast_nullable_to_non_nullable
as bool,creadaEn: null == creadaEn ? _self.creadaEn : creadaEn // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [NotificationDto].
extension NotificationDtoPatterns on NotificationDto {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NotificationDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NotificationDto() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NotificationDto value)  $default,){
final _that = this;
switch (_that) {
case _NotificationDto():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NotificationDto value)?  $default,){
final _that = this;
switch (_that) {
case _NotificationDto() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'notificacion_id')  int notificacionId,  String tipo,  String titulo,  String cuerpo,  String? ruta,  bool leida, @JsonKey(name: 'creada_en')  DateTime creadaEn)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NotificationDto() when $default != null:
return $default(_that.notificacionId,_that.tipo,_that.titulo,_that.cuerpo,_that.ruta,_that.leida,_that.creadaEn);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'notificacion_id')  int notificacionId,  String tipo,  String titulo,  String cuerpo,  String? ruta,  bool leida, @JsonKey(name: 'creada_en')  DateTime creadaEn)  $default,) {final _that = this;
switch (_that) {
case _NotificationDto():
return $default(_that.notificacionId,_that.tipo,_that.titulo,_that.cuerpo,_that.ruta,_that.leida,_that.creadaEn);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'notificacion_id')  int notificacionId,  String tipo,  String titulo,  String cuerpo,  String? ruta,  bool leida, @JsonKey(name: 'creada_en')  DateTime creadaEn)?  $default,) {final _that = this;
switch (_that) {
case _NotificationDto() when $default != null:
return $default(_that.notificacionId,_that.tipo,_that.titulo,_that.cuerpo,_that.ruta,_that.leida,_that.creadaEn);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NotificationDto extends NotificationDto {
  const _NotificationDto({@JsonKey(name: 'notificacion_id') required this.notificacionId, required this.tipo, required this.titulo, required this.cuerpo, this.ruta, required this.leida, @JsonKey(name: 'creada_en') required this.creadaEn}): super._();
  factory _NotificationDto.fromJson(Map<String, dynamic> json) => _$NotificationDtoFromJson(json);

@override@JsonKey(name: 'notificacion_id') final  int notificacionId;
@override final  String tipo;
@override final  String titulo;
@override final  String cuerpo;
@override final  String? ruta;
@override final  bool leida;
@override@JsonKey(name: 'creada_en') final  DateTime creadaEn;

/// Create a copy of NotificationDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NotificationDtoCopyWith<_NotificationDto> get copyWith => __$NotificationDtoCopyWithImpl<_NotificationDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NotificationDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _NotificationDto&&(identical(other.notificacionId, notificacionId) || other.notificacionId == notificacionId)&&(identical(other.tipo, tipo) || other.tipo == tipo)&&(identical(other.titulo, titulo) || other.titulo == titulo)&&(identical(other.cuerpo, cuerpo) || other.cuerpo == cuerpo)&&(identical(other.ruta, ruta) || other.ruta == ruta)&&(identical(other.leida, leida) || other.leida == leida)&&(identical(other.creadaEn, creadaEn) || other.creadaEn == creadaEn));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,notificacionId,tipo,titulo,cuerpo,ruta,leida,creadaEn);
}

@override
String toString() {
    return 'NotificationDto(notificacionId: $notificacionId, tipo: $tipo, titulo: $titulo, cuerpo: $cuerpo, ruta: $ruta, leida: $leida, creadaEn: $creadaEn)';
}


}

/// @nodoc
abstract mixin class _$NotificationDtoCopyWith<$Res> implements $NotificationDtoCopyWith<$Res> {
  factory _$NotificationDtoCopyWith(_NotificationDto value, $Res Function(_NotificationDto) _then) = __$NotificationDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'notificacion_id') int notificacionId, String tipo, String titulo, String cuerpo, String? ruta, bool leida,@JsonKey(name: 'creada_en') DateTime creadaEn
});




}
/// @nodoc
class __$NotificationDtoCopyWithImpl<$Res>
    implements _$NotificationDtoCopyWith<$Res> {
  __$NotificationDtoCopyWithImpl(this._self, this._then);

  final _NotificationDto _self;
  final $Res Function(_NotificationDto) _then;

/// Create a copy of NotificationDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? notificacionId = null,Object? tipo = null,Object? titulo = null,Object? cuerpo = null,Object? ruta = freezed,Object? leida = null,Object? creadaEn = null,}) {
  return _then(_NotificationDto(
notificacionId: null == notificacionId ? _self.notificacionId : notificacionId // ignore: cast_nullable_to_non_nullable
as int,tipo: null == tipo ? _self.tipo : tipo // ignore: cast_nullable_to_non_nullable
as String,titulo: null == titulo ? _self.titulo : titulo // ignore: cast_nullable_to_non_nullable
as String,cuerpo: null == cuerpo ? _self.cuerpo : cuerpo // ignore: cast_nullable_to_non_nullable
as String,ruta: freezed == ruta ? _self.ruta : ruta // ignore: cast_nullable_to_non_nullable
as String?,leida: null == leida ? _self.leida : leida // ignore: cast_nullable_to_non_nullable
as bool,creadaEn: null == creadaEn ? _self.creadaEn : creadaEn // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
