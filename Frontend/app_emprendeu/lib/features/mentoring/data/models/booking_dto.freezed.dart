// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'booking_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MentorDto {

@JsonKey(name: 'usuario_id') int get usuarioId; String get nombre; String? get especialidad; bool get bloqueado;@JsonKey(name: 'motivo_bloqueo') String? get motivoBloqueo;
/// Create a copy of MentorDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MentorDtoCopyWith<MentorDto> get copyWith => _$MentorDtoCopyWithImpl<MentorDto>(this as MentorDto, _$identity);

  /// Serializes this MentorDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as MentorDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MentorDto&&(identical(other.usuarioId, _this.usuarioId) || other.usuarioId == _this.usuarioId)&&(identical(other.nombre, _this.nombre) || other.nombre == _this.nombre)&&(identical(other.especialidad, _this.especialidad) || other.especialidad == _this.especialidad)&&(identical(other.bloqueado, _this.bloqueado) || other.bloqueado == _this.bloqueado)&&(identical(other.motivoBloqueo, _this.motivoBloqueo) || other.motivoBloqueo == _this.motivoBloqueo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as MentorDto;
  return Object.hash(runtimeType,_this.usuarioId,_this.nombre,_this.especialidad,_this.bloqueado,_this.motivoBloqueo);
}

@override
String toString() {
  final _this = this as MentorDto;
  return 'MentorDto(usuarioId: ${_this.usuarioId}, nombre: ${_this.nombre}, especialidad: ${_this.especialidad}, bloqueado: ${_this.bloqueado}, motivoBloqueo: ${_this.motivoBloqueo})';
}


}

/// @nodoc
abstract mixin class $MentorDtoCopyWith<$Res>  {
  factory $MentorDtoCopyWith(MentorDto value, $Res Function(MentorDto) _then) = _$MentorDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'usuario_id') int usuarioId, String nombre, String? especialidad, bool bloqueado,@JsonKey(name: 'motivo_bloqueo') String? motivoBloqueo
});




}
/// @nodoc
class _$MentorDtoCopyWithImpl<$Res>
    implements $MentorDtoCopyWith<$Res> {
  _$MentorDtoCopyWithImpl(this._self, this._then);

  final MentorDto _self;
  final $Res Function(MentorDto) _then;

/// Create a copy of MentorDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? usuarioId = null,Object? nombre = null,Object? especialidad = freezed,Object? bloqueado = null,Object? motivoBloqueo = freezed,}) {
  return _then(MentorDto(
usuarioId: null == usuarioId ? _self.usuarioId : usuarioId // ignore: cast_nullable_to_non_nullable
as int,nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,especialidad: freezed == especialidad ? _self.especialidad : especialidad // ignore: cast_nullable_to_non_nullable
as String?,bloqueado: null == bloqueado ? _self.bloqueado : bloqueado // ignore: cast_nullable_to_non_nullable
as bool,motivoBloqueo: freezed == motivoBloqueo ? _self.motivoBloqueo : motivoBloqueo // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MentorDto].
extension MentorDtoPatterns on MentorDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MentorDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MentorDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MentorDto value)  $default,){
final _that = this;
switch (_that) {
case _MentorDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MentorDto value)?  $default,){
final _that = this;
switch (_that) {
case _MentorDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'usuario_id')  int usuarioId,  String nombre,  String? especialidad,  bool bloqueado, @JsonKey(name: 'motivo_bloqueo')  String? motivoBloqueo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MentorDto() when $default != null:
return $default(_that.usuarioId,_that.nombre,_that.especialidad,_that.bloqueado,_that.motivoBloqueo);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'usuario_id')  int usuarioId,  String nombre,  String? especialidad,  bool bloqueado, @JsonKey(name: 'motivo_bloqueo')  String? motivoBloqueo)  $default,) {final _that = this;
switch (_that) {
case _MentorDto():
return $default(_that.usuarioId,_that.nombre,_that.especialidad,_that.bloqueado,_that.motivoBloqueo);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'usuario_id')  int usuarioId,  String nombre,  String? especialidad,  bool bloqueado, @JsonKey(name: 'motivo_bloqueo')  String? motivoBloqueo)?  $default,) {final _that = this;
switch (_that) {
case _MentorDto() when $default != null:
return $default(_that.usuarioId,_that.nombre,_that.especialidad,_that.bloqueado,_that.motivoBloqueo);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MentorDto extends MentorDto {
  const _MentorDto({@JsonKey(name: 'usuario_id') required this.usuarioId, required this.nombre, this.especialidad, this.bloqueado = false, @JsonKey(name: 'motivo_bloqueo') this.motivoBloqueo}): super._();
  factory _MentorDto.fromJson(Map<String, dynamic> json) => _$MentorDtoFromJson(json);

@override@JsonKey(name: 'usuario_id') final  int usuarioId;
@override final  String nombre;
@override final  String? especialidad;
@override@JsonKey() final  bool bloqueado;
@override@JsonKey(name: 'motivo_bloqueo') final  String? motivoBloqueo;

/// Create a copy of MentorDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MentorDtoCopyWith<_MentorDto> get copyWith => __$MentorDtoCopyWithImpl<_MentorDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MentorDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MentorDto&&(identical(other.usuarioId, usuarioId) || other.usuarioId == usuarioId)&&(identical(other.nombre, nombre) || other.nombre == nombre)&&(identical(other.especialidad, especialidad) || other.especialidad == especialidad)&&(identical(other.bloqueado, bloqueado) || other.bloqueado == bloqueado)&&(identical(other.motivoBloqueo, motivoBloqueo) || other.motivoBloqueo == motivoBloqueo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,usuarioId,nombre,especialidad,bloqueado,motivoBloqueo);
}

@override
String toString() {
    return 'MentorDto(usuarioId: $usuarioId, nombre: $nombre, especialidad: $especialidad, bloqueado: $bloqueado, motivoBloqueo: $motivoBloqueo)';
}


}

/// @nodoc
abstract mixin class _$MentorDtoCopyWith<$Res> implements $MentorDtoCopyWith<$Res> {
  factory _$MentorDtoCopyWith(_MentorDto value, $Res Function(_MentorDto) _then) = __$MentorDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'usuario_id') int usuarioId, String nombre, String? especialidad, bool bloqueado,@JsonKey(name: 'motivo_bloqueo') String? motivoBloqueo
});




}
/// @nodoc
class __$MentorDtoCopyWithImpl<$Res>
    implements _$MentorDtoCopyWith<$Res> {
  __$MentorDtoCopyWithImpl(this._self, this._then);

  final _MentorDto _self;
  final $Res Function(_MentorDto) _then;

/// Create a copy of MentorDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? usuarioId = null,Object? nombre = null,Object? especialidad = freezed,Object? bloqueado = null,Object? motivoBloqueo = freezed,}) {
  return _then(_MentorDto(
usuarioId: null == usuarioId ? _self.usuarioId : usuarioId // ignore: cast_nullable_to_non_nullable
as int,nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,especialidad: freezed == especialidad ? _self.especialidad : especialidad // ignore: cast_nullable_to_non_nullable
as String?,bloqueado: null == bloqueado ? _self.bloqueado : bloqueado // ignore: cast_nullable_to_non_nullable
as bool,motivoBloqueo: freezed == motivoBloqueo ? _self.motivoBloqueo : motivoBloqueo // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$SlotDto {

 DateTime get inicio; String get hora; bool get disponible;
/// Create a copy of SlotDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SlotDtoCopyWith<SlotDto> get copyWith => _$SlotDtoCopyWithImpl<SlotDto>(this as SlotDto, _$identity);

  /// Serializes this SlotDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SlotDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SlotDto&&(identical(other.inicio, _this.inicio) || other.inicio == _this.inicio)&&(identical(other.hora, _this.hora) || other.hora == _this.hora)&&(identical(other.disponible, _this.disponible) || other.disponible == _this.disponible));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SlotDto;
  return Object.hash(runtimeType,_this.inicio,_this.hora,_this.disponible);
}

@override
String toString() {
  final _this = this as SlotDto;
  return 'SlotDto(inicio: ${_this.inicio}, hora: ${_this.hora}, disponible: ${_this.disponible})';
}


}

/// @nodoc
abstract mixin class $SlotDtoCopyWith<$Res>  {
  factory $SlotDtoCopyWith(SlotDto value, $Res Function(SlotDto) _then) = _$SlotDtoCopyWithImpl;
@useResult
$Res call({
 DateTime inicio, String hora, bool disponible
});




}
/// @nodoc
class _$SlotDtoCopyWithImpl<$Res>
    implements $SlotDtoCopyWith<$Res> {
  _$SlotDtoCopyWithImpl(this._self, this._then);

  final SlotDto _self;
  final $Res Function(SlotDto) _then;

/// Create a copy of SlotDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? inicio = null,Object? hora = null,Object? disponible = null,}) {
  return _then(SlotDto(
inicio: null == inicio ? _self.inicio : inicio // ignore: cast_nullable_to_non_nullable
as DateTime,hora: null == hora ? _self.hora : hora // ignore: cast_nullable_to_non_nullable
as String,disponible: null == disponible ? _self.disponible : disponible // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [SlotDto].
extension SlotDtoPatterns on SlotDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SlotDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SlotDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SlotDto value)  $default,){
final _that = this;
switch (_that) {
case _SlotDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SlotDto value)?  $default,){
final _that = this;
switch (_that) {
case _SlotDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime inicio,  String hora,  bool disponible)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SlotDto() when $default != null:
return $default(_that.inicio,_that.hora,_that.disponible);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime inicio,  String hora,  bool disponible)  $default,) {final _that = this;
switch (_that) {
case _SlotDto():
return $default(_that.inicio,_that.hora,_that.disponible);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime inicio,  String hora,  bool disponible)?  $default,) {final _that = this;
switch (_that) {
case _SlotDto() when $default != null:
return $default(_that.inicio,_that.hora,_that.disponible);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SlotDto extends SlotDto {
  const _SlotDto({required this.inicio, required this.hora, required this.disponible}): super._();
  factory _SlotDto.fromJson(Map<String, dynamic> json) => _$SlotDtoFromJson(json);

@override final  DateTime inicio;
@override final  String hora;
@override final  bool disponible;

/// Create a copy of SlotDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SlotDtoCopyWith<_SlotDto> get copyWith => __$SlotDtoCopyWithImpl<_SlotDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SlotDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SlotDto&&(identical(other.inicio, inicio) || other.inicio == inicio)&&(identical(other.hora, hora) || other.hora == hora)&&(identical(other.disponible, disponible) || other.disponible == disponible));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,inicio,hora,disponible);
}

@override
String toString() {
    return 'SlotDto(inicio: $inicio, hora: $hora, disponible: $disponible)';
}


}

/// @nodoc
abstract mixin class _$SlotDtoCopyWith<$Res> implements $SlotDtoCopyWith<$Res> {
  factory _$SlotDtoCopyWith(_SlotDto value, $Res Function(_SlotDto) _then) = __$SlotDtoCopyWithImpl;
@override @useResult
$Res call({
 DateTime inicio, String hora, bool disponible
});




}
/// @nodoc
class __$SlotDtoCopyWithImpl<$Res>
    implements _$SlotDtoCopyWith<$Res> {
  __$SlotDtoCopyWithImpl(this._self, this._then);

  final _SlotDto _self;
  final $Res Function(_SlotDto) _then;

/// Create a copy of SlotDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? inicio = null,Object? hora = null,Object? disponible = null,}) {
  return _then(_SlotDto(
inicio: null == inicio ? _self.inicio : inicio // ignore: cast_nullable_to_non_nullable
as DateTime,hora: null == hora ? _self.hora : hora // ignore: cast_nullable_to_non_nullable
as String,disponible: null == disponible ? _self.disponible : disponible // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$BookingStatusDto {

 bool get habilitado; String? get motivo; String? get etapa;
/// Create a copy of BookingStatusDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookingStatusDtoCopyWith<BookingStatusDto> get copyWith => _$BookingStatusDtoCopyWithImpl<BookingStatusDto>(this as BookingStatusDto, _$identity);

  /// Serializes this BookingStatusDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BookingStatusDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookingStatusDto&&(identical(other.habilitado, _this.habilitado) || other.habilitado == _this.habilitado)&&(identical(other.motivo, _this.motivo) || other.motivo == _this.motivo)&&(identical(other.etapa, _this.etapa) || other.etapa == _this.etapa));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BookingStatusDto;
  return Object.hash(runtimeType,_this.habilitado,_this.motivo,_this.etapa);
}

@override
String toString() {
  final _this = this as BookingStatusDto;
  return 'BookingStatusDto(habilitado: ${_this.habilitado}, motivo: ${_this.motivo}, etapa: ${_this.etapa})';
}


}

/// @nodoc
abstract mixin class $BookingStatusDtoCopyWith<$Res>  {
  factory $BookingStatusDtoCopyWith(BookingStatusDto value, $Res Function(BookingStatusDto) _then) = _$BookingStatusDtoCopyWithImpl;
@useResult
$Res call({
 bool habilitado, String? motivo, String? etapa
});




}
/// @nodoc
class _$BookingStatusDtoCopyWithImpl<$Res>
    implements $BookingStatusDtoCopyWith<$Res> {
  _$BookingStatusDtoCopyWithImpl(this._self, this._then);

  final BookingStatusDto _self;
  final $Res Function(BookingStatusDto) _then;

/// Create a copy of BookingStatusDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? habilitado = null,Object? motivo = freezed,Object? etapa = freezed,}) {
  return _then(BookingStatusDto(
habilitado: null == habilitado ? _self.habilitado : habilitado // ignore: cast_nullable_to_non_nullable
as bool,motivo: freezed == motivo ? _self.motivo : motivo // ignore: cast_nullable_to_non_nullable
as String?,etapa: freezed == etapa ? _self.etapa : etapa // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BookingStatusDto].
extension BookingStatusDtoPatterns on BookingStatusDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookingStatusDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookingStatusDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookingStatusDto value)  $default,){
final _that = this;
switch (_that) {
case _BookingStatusDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookingStatusDto value)?  $default,){
final _that = this;
switch (_that) {
case _BookingStatusDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool habilitado,  String? motivo,  String? etapa)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BookingStatusDto() when $default != null:
return $default(_that.habilitado,_that.motivo,_that.etapa);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool habilitado,  String? motivo,  String? etapa)  $default,) {final _that = this;
switch (_that) {
case _BookingStatusDto():
return $default(_that.habilitado,_that.motivo,_that.etapa);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool habilitado,  String? motivo,  String? etapa)?  $default,) {final _that = this;
switch (_that) {
case _BookingStatusDto() when $default != null:
return $default(_that.habilitado,_that.motivo,_that.etapa);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BookingStatusDto extends BookingStatusDto {
  const _BookingStatusDto({required this.habilitado, this.motivo, this.etapa}): super._();
  factory _BookingStatusDto.fromJson(Map<String, dynamic> json) => _$BookingStatusDtoFromJson(json);

@override final  bool habilitado;
@override final  String? motivo;
@override final  String? etapa;

/// Create a copy of BookingStatusDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookingStatusDtoCopyWith<_BookingStatusDto> get copyWith => __$BookingStatusDtoCopyWithImpl<_BookingStatusDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BookingStatusDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookingStatusDto&&(identical(other.habilitado, habilitado) || other.habilitado == habilitado)&&(identical(other.motivo, motivo) || other.motivo == motivo)&&(identical(other.etapa, etapa) || other.etapa == etapa));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,habilitado,motivo,etapa);
}

@override
String toString() {
    return 'BookingStatusDto(habilitado: $habilitado, motivo: $motivo, etapa: $etapa)';
}


}

/// @nodoc
abstract mixin class _$BookingStatusDtoCopyWith<$Res> implements $BookingStatusDtoCopyWith<$Res> {
  factory _$BookingStatusDtoCopyWith(_BookingStatusDto value, $Res Function(_BookingStatusDto) _then) = __$BookingStatusDtoCopyWithImpl;
@override @useResult
$Res call({
 bool habilitado, String? motivo, String? etapa
});




}
/// @nodoc
class __$BookingStatusDtoCopyWithImpl<$Res>
    implements _$BookingStatusDtoCopyWith<$Res> {
  __$BookingStatusDtoCopyWithImpl(this._self, this._then);

  final _BookingStatusDto _self;
  final $Res Function(_BookingStatusDto) _then;

/// Create a copy of BookingStatusDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? habilitado = null,Object? motivo = freezed,Object? etapa = freezed,}) {
  return _then(_BookingStatusDto(
habilitado: null == habilitado ? _self.habilitado : habilitado // ignore: cast_nullable_to_non_nullable
as bool,motivo: freezed == motivo ? _self.motivo : motivo // ignore: cast_nullable_to_non_nullable
as String?,etapa: freezed == etapa ? _self.etapa : etapa // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$MentoringSessionDto {

@JsonKey(name: 'sesion_id') int get sesionId; String? get estado; String? get tema; String? get modalidad; String? get mentor; String? get especialidad; String? get emprendimiento;@JsonKey(name: 'fecha_programada') DateTime? get fechaProgramada;@JsonKey(name: 'fecha_realizada') DateTime? get fechaRealizada; String? get observaciones;@JsonKey(name: 'total_recomendaciones') int get totalRecomendaciones;@JsonKey(name: 'total_compromisos') int get totalCompromisos;
/// Create a copy of MentoringSessionDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MentoringSessionDtoCopyWith<MentoringSessionDto> get copyWith => _$MentoringSessionDtoCopyWithImpl<MentoringSessionDto>(this as MentoringSessionDto, _$identity);

  /// Serializes this MentoringSessionDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as MentoringSessionDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MentoringSessionDto&&(identical(other.sesionId, _this.sesionId) || other.sesionId == _this.sesionId)&&(identical(other.estado, _this.estado) || other.estado == _this.estado)&&(identical(other.tema, _this.tema) || other.tema == _this.tema)&&(identical(other.modalidad, _this.modalidad) || other.modalidad == _this.modalidad)&&(identical(other.mentor, _this.mentor) || other.mentor == _this.mentor)&&(identical(other.especialidad, _this.especialidad) || other.especialidad == _this.especialidad)&&(identical(other.emprendimiento, _this.emprendimiento) || other.emprendimiento == _this.emprendimiento)&&(identical(other.fechaProgramada, _this.fechaProgramada) || other.fechaProgramada == _this.fechaProgramada)&&(identical(other.fechaRealizada, _this.fechaRealizada) || other.fechaRealizada == _this.fechaRealizada)&&(identical(other.observaciones, _this.observaciones) || other.observaciones == _this.observaciones)&&(identical(other.totalRecomendaciones, _this.totalRecomendaciones) || other.totalRecomendaciones == _this.totalRecomendaciones)&&(identical(other.totalCompromisos, _this.totalCompromisos) || other.totalCompromisos == _this.totalCompromisos));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as MentoringSessionDto;
  return Object.hash(runtimeType,_this.sesionId,_this.estado,_this.tema,_this.modalidad,_this.mentor,_this.especialidad,_this.emprendimiento,_this.fechaProgramada,_this.fechaRealizada,_this.observaciones,_this.totalRecomendaciones,_this.totalCompromisos);
}

@override
String toString() {
  final _this = this as MentoringSessionDto;
  return 'MentoringSessionDto(sesionId: ${_this.sesionId}, estado: ${_this.estado}, tema: ${_this.tema}, modalidad: ${_this.modalidad}, mentor: ${_this.mentor}, especialidad: ${_this.especialidad}, emprendimiento: ${_this.emprendimiento}, fechaProgramada: ${_this.fechaProgramada}, fechaRealizada: ${_this.fechaRealizada}, observaciones: ${_this.observaciones}, totalRecomendaciones: ${_this.totalRecomendaciones}, totalCompromisos: ${_this.totalCompromisos})';
}


}

/// @nodoc
abstract mixin class $MentoringSessionDtoCopyWith<$Res>  {
  factory $MentoringSessionDtoCopyWith(MentoringSessionDto value, $Res Function(MentoringSessionDto) _then) = _$MentoringSessionDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'sesion_id') int sesionId, String? estado, String? tema, String? modalidad, String? mentor, String? especialidad, String? emprendimiento,@JsonKey(name: 'fecha_programada') DateTime? fechaProgramada,@JsonKey(name: 'fecha_realizada') DateTime? fechaRealizada, String? observaciones,@JsonKey(name: 'total_recomendaciones') int totalRecomendaciones,@JsonKey(name: 'total_compromisos') int totalCompromisos
});




}
/// @nodoc
class _$MentoringSessionDtoCopyWithImpl<$Res>
    implements $MentoringSessionDtoCopyWith<$Res> {
  _$MentoringSessionDtoCopyWithImpl(this._self, this._then);

  final MentoringSessionDto _self;
  final $Res Function(MentoringSessionDto) _then;

/// Create a copy of MentoringSessionDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sesionId = null,Object? estado = freezed,Object? tema = freezed,Object? modalidad = freezed,Object? mentor = freezed,Object? especialidad = freezed,Object? emprendimiento = freezed,Object? fechaProgramada = freezed,Object? fechaRealizada = freezed,Object? observaciones = freezed,Object? totalRecomendaciones = null,Object? totalCompromisos = null,}) {
  return _then(MentoringSessionDto(
sesionId: null == sesionId ? _self.sesionId : sesionId // ignore: cast_nullable_to_non_nullable
as int,estado: freezed == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as String?,tema: freezed == tema ? _self.tema : tema // ignore: cast_nullable_to_non_nullable
as String?,modalidad: freezed == modalidad ? _self.modalidad : modalidad // ignore: cast_nullable_to_non_nullable
as String?,mentor: freezed == mentor ? _self.mentor : mentor // ignore: cast_nullable_to_non_nullable
as String?,especialidad: freezed == especialidad ? _self.especialidad : especialidad // ignore: cast_nullable_to_non_nullable
as String?,emprendimiento: freezed == emprendimiento ? _self.emprendimiento : emprendimiento // ignore: cast_nullable_to_non_nullable
as String?,fechaProgramada: freezed == fechaProgramada ? _self.fechaProgramada : fechaProgramada // ignore: cast_nullable_to_non_nullable
as DateTime?,fechaRealizada: freezed == fechaRealizada ? _self.fechaRealizada : fechaRealizada // ignore: cast_nullable_to_non_nullable
as DateTime?,observaciones: freezed == observaciones ? _self.observaciones : observaciones // ignore: cast_nullable_to_non_nullable
as String?,totalRecomendaciones: null == totalRecomendaciones ? _self.totalRecomendaciones : totalRecomendaciones // ignore: cast_nullable_to_non_nullable
as int,totalCompromisos: null == totalCompromisos ? _self.totalCompromisos : totalCompromisos // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [MentoringSessionDto].
extension MentoringSessionDtoPatterns on MentoringSessionDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MentoringSessionDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MentoringSessionDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MentoringSessionDto value)  $default,){
final _that = this;
switch (_that) {
case _MentoringSessionDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MentoringSessionDto value)?  $default,){
final _that = this;
switch (_that) {
case _MentoringSessionDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'sesion_id')  int sesionId,  String? estado,  String? tema,  String? modalidad,  String? mentor,  String? especialidad,  String? emprendimiento, @JsonKey(name: 'fecha_programada')  DateTime? fechaProgramada, @JsonKey(name: 'fecha_realizada')  DateTime? fechaRealizada,  String? observaciones, @JsonKey(name: 'total_recomendaciones')  int totalRecomendaciones, @JsonKey(name: 'total_compromisos')  int totalCompromisos)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MentoringSessionDto() when $default != null:
return $default(_that.sesionId,_that.estado,_that.tema,_that.modalidad,_that.mentor,_that.especialidad,_that.emprendimiento,_that.fechaProgramada,_that.fechaRealizada,_that.observaciones,_that.totalRecomendaciones,_that.totalCompromisos);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'sesion_id')  int sesionId,  String? estado,  String? tema,  String? modalidad,  String? mentor,  String? especialidad,  String? emprendimiento, @JsonKey(name: 'fecha_programada')  DateTime? fechaProgramada, @JsonKey(name: 'fecha_realizada')  DateTime? fechaRealizada,  String? observaciones, @JsonKey(name: 'total_recomendaciones')  int totalRecomendaciones, @JsonKey(name: 'total_compromisos')  int totalCompromisos)  $default,) {final _that = this;
switch (_that) {
case _MentoringSessionDto():
return $default(_that.sesionId,_that.estado,_that.tema,_that.modalidad,_that.mentor,_that.especialidad,_that.emprendimiento,_that.fechaProgramada,_that.fechaRealizada,_that.observaciones,_that.totalRecomendaciones,_that.totalCompromisos);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'sesion_id')  int sesionId,  String? estado,  String? tema,  String? modalidad,  String? mentor,  String? especialidad,  String? emprendimiento, @JsonKey(name: 'fecha_programada')  DateTime? fechaProgramada, @JsonKey(name: 'fecha_realizada')  DateTime? fechaRealizada,  String? observaciones, @JsonKey(name: 'total_recomendaciones')  int totalRecomendaciones, @JsonKey(name: 'total_compromisos')  int totalCompromisos)?  $default,) {final _that = this;
switch (_that) {
case _MentoringSessionDto() when $default != null:
return $default(_that.sesionId,_that.estado,_that.tema,_that.modalidad,_that.mentor,_that.especialidad,_that.emprendimiento,_that.fechaProgramada,_that.fechaRealizada,_that.observaciones,_that.totalRecomendaciones,_that.totalCompromisos);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MentoringSessionDto extends MentoringSessionDto {
  const _MentoringSessionDto({@JsonKey(name: 'sesion_id') required this.sesionId, this.estado, this.tema, this.modalidad, this.mentor, this.especialidad, this.emprendimiento, @JsonKey(name: 'fecha_programada') this.fechaProgramada, @JsonKey(name: 'fecha_realizada') this.fechaRealizada, this.observaciones, @JsonKey(name: 'total_recomendaciones') this.totalRecomendaciones = 0, @JsonKey(name: 'total_compromisos') this.totalCompromisos = 0}): super._();
  factory _MentoringSessionDto.fromJson(Map<String, dynamic> json) => _$MentoringSessionDtoFromJson(json);

@override@JsonKey(name: 'sesion_id') final  int sesionId;
@override final  String? estado;
@override final  String? tema;
@override final  String? modalidad;
@override final  String? mentor;
@override final  String? especialidad;
@override final  String? emprendimiento;
@override@JsonKey(name: 'fecha_programada') final  DateTime? fechaProgramada;
@override@JsonKey(name: 'fecha_realizada') final  DateTime? fechaRealizada;
@override final  String? observaciones;
@override@JsonKey(name: 'total_recomendaciones') final  int totalRecomendaciones;
@override@JsonKey(name: 'total_compromisos') final  int totalCompromisos;

/// Create a copy of MentoringSessionDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MentoringSessionDtoCopyWith<_MentoringSessionDto> get copyWith => __$MentoringSessionDtoCopyWithImpl<_MentoringSessionDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MentoringSessionDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MentoringSessionDto&&(identical(other.sesionId, sesionId) || other.sesionId == sesionId)&&(identical(other.estado, estado) || other.estado == estado)&&(identical(other.tema, tema) || other.tema == tema)&&(identical(other.modalidad, modalidad) || other.modalidad == modalidad)&&(identical(other.mentor, mentor) || other.mentor == mentor)&&(identical(other.especialidad, especialidad) || other.especialidad == especialidad)&&(identical(other.emprendimiento, emprendimiento) || other.emprendimiento == emprendimiento)&&(identical(other.fechaProgramada, fechaProgramada) || other.fechaProgramada == fechaProgramada)&&(identical(other.fechaRealizada, fechaRealizada) || other.fechaRealizada == fechaRealizada)&&(identical(other.observaciones, observaciones) || other.observaciones == observaciones)&&(identical(other.totalRecomendaciones, totalRecomendaciones) || other.totalRecomendaciones == totalRecomendaciones)&&(identical(other.totalCompromisos, totalCompromisos) || other.totalCompromisos == totalCompromisos));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,sesionId,estado,tema,modalidad,mentor,especialidad,emprendimiento,fechaProgramada,fechaRealizada,observaciones,totalRecomendaciones,totalCompromisos);
}

@override
String toString() {
    return 'MentoringSessionDto(sesionId: $sesionId, estado: $estado, tema: $tema, modalidad: $modalidad, mentor: $mentor, especialidad: $especialidad, emprendimiento: $emprendimiento, fechaProgramada: $fechaProgramada, fechaRealizada: $fechaRealizada, observaciones: $observaciones, totalRecomendaciones: $totalRecomendaciones, totalCompromisos: $totalCompromisos)';
}


}

/// @nodoc
abstract mixin class _$MentoringSessionDtoCopyWith<$Res> implements $MentoringSessionDtoCopyWith<$Res> {
  factory _$MentoringSessionDtoCopyWith(_MentoringSessionDto value, $Res Function(_MentoringSessionDto) _then) = __$MentoringSessionDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'sesion_id') int sesionId, String? estado, String? tema, String? modalidad, String? mentor, String? especialidad, String? emprendimiento,@JsonKey(name: 'fecha_programada') DateTime? fechaProgramada,@JsonKey(name: 'fecha_realizada') DateTime? fechaRealizada, String? observaciones,@JsonKey(name: 'total_recomendaciones') int totalRecomendaciones,@JsonKey(name: 'total_compromisos') int totalCompromisos
});




}
/// @nodoc
class __$MentoringSessionDtoCopyWithImpl<$Res>
    implements _$MentoringSessionDtoCopyWith<$Res> {
  __$MentoringSessionDtoCopyWithImpl(this._self, this._then);

  final _MentoringSessionDto _self;
  final $Res Function(_MentoringSessionDto) _then;

/// Create a copy of MentoringSessionDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sesionId = null,Object? estado = freezed,Object? tema = freezed,Object? modalidad = freezed,Object? mentor = freezed,Object? especialidad = freezed,Object? emprendimiento = freezed,Object? fechaProgramada = freezed,Object? fechaRealizada = freezed,Object? observaciones = freezed,Object? totalRecomendaciones = null,Object? totalCompromisos = null,}) {
  return _then(_MentoringSessionDto(
sesionId: null == sesionId ? _self.sesionId : sesionId // ignore: cast_nullable_to_non_nullable
as int,estado: freezed == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as String?,tema: freezed == tema ? _self.tema : tema // ignore: cast_nullable_to_non_nullable
as String?,modalidad: freezed == modalidad ? _self.modalidad : modalidad // ignore: cast_nullable_to_non_nullable
as String?,mentor: freezed == mentor ? _self.mentor : mentor // ignore: cast_nullable_to_non_nullable
as String?,especialidad: freezed == especialidad ? _self.especialidad : especialidad // ignore: cast_nullable_to_non_nullable
as String?,emprendimiento: freezed == emprendimiento ? _self.emprendimiento : emprendimiento // ignore: cast_nullable_to_non_nullable
as String?,fechaProgramada: freezed == fechaProgramada ? _self.fechaProgramada : fechaProgramada // ignore: cast_nullable_to_non_nullable
as DateTime?,fechaRealizada: freezed == fechaRealizada ? _self.fechaRealizada : fechaRealizada // ignore: cast_nullable_to_non_nullable
as DateTime?,observaciones: freezed == observaciones ? _self.observaciones : observaciones // ignore: cast_nullable_to_non_nullable
as String?,totalRecomendaciones: null == totalRecomendaciones ? _self.totalRecomendaciones : totalRecomendaciones // ignore: cast_nullable_to_non_nullable
as int,totalCompromisos: null == totalCompromisos ? _self.totalCompromisos : totalCompromisos // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
