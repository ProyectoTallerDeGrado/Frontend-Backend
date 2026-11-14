// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'training_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TrainingDto {

@JsonKey(name: 'capacitacion_id') int get capacitacionId; String get titulo; String? get descripcion; DateTime? get fecha; String? get modalidad; String? get tipo; String? get estado; bool? get inscrito; bool? get asistencia;
/// Create a copy of TrainingDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrainingDtoCopyWith<TrainingDto> get copyWith => _$TrainingDtoCopyWithImpl<TrainingDto>(this as TrainingDto, _$identity);

  /// Serializes this TrainingDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as TrainingDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrainingDto&&(identical(other.capacitacionId, _this.capacitacionId) || other.capacitacionId == _this.capacitacionId)&&(identical(other.titulo, _this.titulo) || other.titulo == _this.titulo)&&(identical(other.descripcion, _this.descripcion) || other.descripcion == _this.descripcion)&&(identical(other.fecha, _this.fecha) || other.fecha == _this.fecha)&&(identical(other.modalidad, _this.modalidad) || other.modalidad == _this.modalidad)&&(identical(other.tipo, _this.tipo) || other.tipo == _this.tipo)&&(identical(other.estado, _this.estado) || other.estado == _this.estado)&&(identical(other.inscrito, _this.inscrito) || other.inscrito == _this.inscrito)&&(identical(other.asistencia, _this.asistencia) || other.asistencia == _this.asistencia));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TrainingDto;
  return Object.hash(runtimeType,_this.capacitacionId,_this.titulo,_this.descripcion,_this.fecha,_this.modalidad,_this.tipo,_this.estado,_this.inscrito,_this.asistencia);
}

@override
String toString() {
  final _this = this as TrainingDto;
  return 'TrainingDto(capacitacionId: ${_this.capacitacionId}, titulo: ${_this.titulo}, descripcion: ${_this.descripcion}, fecha: ${_this.fecha}, modalidad: ${_this.modalidad}, tipo: ${_this.tipo}, estado: ${_this.estado}, inscrito: ${_this.inscrito}, asistencia: ${_this.asistencia})';
}


}

/// @nodoc
abstract mixin class $TrainingDtoCopyWith<$Res>  {
  factory $TrainingDtoCopyWith(TrainingDto value, $Res Function(TrainingDto) _then) = _$TrainingDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'capacitacion_id') int capacitacionId, String titulo, String? descripcion, DateTime? fecha, String? modalidad, String? tipo, String? estado, bool? inscrito, bool? asistencia
});




}
/// @nodoc
class _$TrainingDtoCopyWithImpl<$Res>
    implements $TrainingDtoCopyWith<$Res> {
  _$TrainingDtoCopyWithImpl(this._self, this._then);

  final TrainingDto _self;
  final $Res Function(TrainingDto) _then;

/// Create a copy of TrainingDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? capacitacionId = null,Object? titulo = null,Object? descripcion = freezed,Object? fecha = freezed,Object? modalidad = freezed,Object? tipo = freezed,Object? estado = freezed,Object? inscrito = freezed,Object? asistencia = freezed,}) {
  return _then(TrainingDto(
capacitacionId: null == capacitacionId ? _self.capacitacionId : capacitacionId // ignore: cast_nullable_to_non_nullable
as int,titulo: null == titulo ? _self.titulo : titulo // ignore: cast_nullable_to_non_nullable
as String,descripcion: freezed == descripcion ? _self.descripcion : descripcion // ignore: cast_nullable_to_non_nullable
as String?,fecha: freezed == fecha ? _self.fecha : fecha // ignore: cast_nullable_to_non_nullable
as DateTime?,modalidad: freezed == modalidad ? _self.modalidad : modalidad // ignore: cast_nullable_to_non_nullable
as String?,tipo: freezed == tipo ? _self.tipo : tipo // ignore: cast_nullable_to_non_nullable
as String?,estado: freezed == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as String?,inscrito: freezed == inscrito ? _self.inscrito : inscrito // ignore: cast_nullable_to_non_nullable
as bool?,asistencia: freezed == asistencia ? _self.asistencia : asistencia // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// Adds pattern-matching-related methods to [TrainingDto].
extension TrainingDtoPatterns on TrainingDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TrainingDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TrainingDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TrainingDto value)  $default,){
final _that = this;
switch (_that) {
case _TrainingDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TrainingDto value)?  $default,){
final _that = this;
switch (_that) {
case _TrainingDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'capacitacion_id')  int capacitacionId,  String titulo,  String? descripcion,  DateTime? fecha,  String? modalidad,  String? tipo,  String? estado,  bool? inscrito,  bool? asistencia)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TrainingDto() when $default != null:
return $default(_that.capacitacionId,_that.titulo,_that.descripcion,_that.fecha,_that.modalidad,_that.tipo,_that.estado,_that.inscrito,_that.asistencia);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'capacitacion_id')  int capacitacionId,  String titulo,  String? descripcion,  DateTime? fecha,  String? modalidad,  String? tipo,  String? estado,  bool? inscrito,  bool? asistencia)  $default,) {final _that = this;
switch (_that) {
case _TrainingDto():
return $default(_that.capacitacionId,_that.titulo,_that.descripcion,_that.fecha,_that.modalidad,_that.tipo,_that.estado,_that.inscrito,_that.asistencia);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'capacitacion_id')  int capacitacionId,  String titulo,  String? descripcion,  DateTime? fecha,  String? modalidad,  String? tipo,  String? estado,  bool? inscrito,  bool? asistencia)?  $default,) {final _that = this;
switch (_that) {
case _TrainingDto() when $default != null:
return $default(_that.capacitacionId,_that.titulo,_that.descripcion,_that.fecha,_that.modalidad,_that.tipo,_that.estado,_that.inscrito,_that.asistencia);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TrainingDto extends TrainingDto {
  const _TrainingDto({@JsonKey(name: 'capacitacion_id') required this.capacitacionId, required this.titulo, this.descripcion, this.fecha, this.modalidad, this.tipo, this.estado, this.inscrito, this.asistencia}): super._();
  factory _TrainingDto.fromJson(Map<String, dynamic> json) => _$TrainingDtoFromJson(json);

@override@JsonKey(name: 'capacitacion_id') final  int capacitacionId;
@override final  String titulo;
@override final  String? descripcion;
@override final  DateTime? fecha;
@override final  String? modalidad;
@override final  String? tipo;
@override final  String? estado;
@override final  bool? inscrito;
@override final  bool? asistencia;

/// Create a copy of TrainingDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrainingDtoCopyWith<_TrainingDto> get copyWith => __$TrainingDtoCopyWithImpl<_TrainingDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TrainingDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TrainingDto&&(identical(other.capacitacionId, capacitacionId) || other.capacitacionId == capacitacionId)&&(identical(other.titulo, titulo) || other.titulo == titulo)&&(identical(other.descripcion, descripcion) || other.descripcion == descripcion)&&(identical(other.fecha, fecha) || other.fecha == fecha)&&(identical(other.modalidad, modalidad) || other.modalidad == modalidad)&&(identical(other.tipo, tipo) || other.tipo == tipo)&&(identical(other.estado, estado) || other.estado == estado)&&(identical(other.inscrito, inscrito) || other.inscrito == inscrito)&&(identical(other.asistencia, asistencia) || other.asistencia == asistencia));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,capacitacionId,titulo,descripcion,fecha,modalidad,tipo,estado,inscrito,asistencia);
}

@override
String toString() {
    return 'TrainingDto(capacitacionId: $capacitacionId, titulo: $titulo, descripcion: $descripcion, fecha: $fecha, modalidad: $modalidad, tipo: $tipo, estado: $estado, inscrito: $inscrito, asistencia: $asistencia)';
}


}

/// @nodoc
abstract mixin class _$TrainingDtoCopyWith<$Res> implements $TrainingDtoCopyWith<$Res> {
  factory _$TrainingDtoCopyWith(_TrainingDto value, $Res Function(_TrainingDto) _then) = __$TrainingDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'capacitacion_id') int capacitacionId, String titulo, String? descripcion, DateTime? fecha, String? modalidad, String? tipo, String? estado, bool? inscrito, bool? asistencia
});




}
/// @nodoc
class __$TrainingDtoCopyWithImpl<$Res>
    implements _$TrainingDtoCopyWith<$Res> {
  __$TrainingDtoCopyWithImpl(this._self, this._then);

  final _TrainingDto _self;
  final $Res Function(_TrainingDto) _then;

/// Create a copy of TrainingDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? capacitacionId = null,Object? titulo = null,Object? descripcion = freezed,Object? fecha = freezed,Object? modalidad = freezed,Object? tipo = freezed,Object? estado = freezed,Object? inscrito = freezed,Object? asistencia = freezed,}) {
  return _then(_TrainingDto(
capacitacionId: null == capacitacionId ? _self.capacitacionId : capacitacionId // ignore: cast_nullable_to_non_nullable
as int,titulo: null == titulo ? _self.titulo : titulo // ignore: cast_nullable_to_non_nullable
as String,descripcion: freezed == descripcion ? _self.descripcion : descripcion // ignore: cast_nullable_to_non_nullable
as String?,fecha: freezed == fecha ? _self.fecha : fecha // ignore: cast_nullable_to_non_nullable
as DateTime?,modalidad: freezed == modalidad ? _self.modalidad : modalidad // ignore: cast_nullable_to_non_nullable
as String?,tipo: freezed == tipo ? _self.tipo : tipo // ignore: cast_nullable_to_non_nullable
as String?,estado: freezed == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as String?,inscrito: freezed == inscrito ? _self.inscrito : inscrito // ignore: cast_nullable_to_non_nullable
as bool?,asistencia: freezed == asistencia ? _self.asistencia : asistencia // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}

// dart format on
