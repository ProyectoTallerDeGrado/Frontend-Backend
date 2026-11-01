// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'mentoring_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CommitmentDto {

@JsonKey(name: 'compromiso_id') int get compromisoId;@JsonKey(name: 'sesion_id') int get sesionId; String? get descripcion; String? get estado;@JsonKey(name: 'fecha_limite') DateTime? get fechaLimite;
/// Create a copy of CommitmentDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommitmentDtoCopyWith<CommitmentDto> get copyWith => _$CommitmentDtoCopyWithImpl<CommitmentDto>(this as CommitmentDto, _$identity);

  /// Serializes this CommitmentDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CommitmentDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommitmentDto&&(identical(other.compromisoId, _this.compromisoId) || other.compromisoId == _this.compromisoId)&&(identical(other.sesionId, _this.sesionId) || other.sesionId == _this.sesionId)&&(identical(other.descripcion, _this.descripcion) || other.descripcion == _this.descripcion)&&(identical(other.estado, _this.estado) || other.estado == _this.estado)&&(identical(other.fechaLimite, _this.fechaLimite) || other.fechaLimite == _this.fechaLimite));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CommitmentDto;
  return Object.hash(runtimeType,_this.compromisoId,_this.sesionId,_this.descripcion,_this.estado,_this.fechaLimite);
}

@override
String toString() {
  final _this = this as CommitmentDto;
  return 'CommitmentDto(compromisoId: ${_this.compromisoId}, sesionId: ${_this.sesionId}, descripcion: ${_this.descripcion}, estado: ${_this.estado}, fechaLimite: ${_this.fechaLimite})';
}


}

/// @nodoc
abstract mixin class $CommitmentDtoCopyWith<$Res>  {
  factory $CommitmentDtoCopyWith(CommitmentDto value, $Res Function(CommitmentDto) _then) = _$CommitmentDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'compromiso_id') int compromisoId,@JsonKey(name: 'sesion_id') int sesionId, String? descripcion, String? estado,@JsonKey(name: 'fecha_limite') DateTime? fechaLimite
});




}
/// @nodoc
class _$CommitmentDtoCopyWithImpl<$Res>
    implements $CommitmentDtoCopyWith<$Res> {
  _$CommitmentDtoCopyWithImpl(this._self, this._then);

  final CommitmentDto _self;
  final $Res Function(CommitmentDto) _then;

/// Create a copy of CommitmentDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? compromisoId = null,Object? sesionId = null,Object? descripcion = freezed,Object? estado = freezed,Object? fechaLimite = freezed,}) {
  return _then(CommitmentDto(
compromisoId: null == compromisoId ? _self.compromisoId : compromisoId // ignore: cast_nullable_to_non_nullable
as int,sesionId: null == sesionId ? _self.sesionId : sesionId // ignore: cast_nullable_to_non_nullable
as int,descripcion: freezed == descripcion ? _self.descripcion : descripcion // ignore: cast_nullable_to_non_nullable
as String?,estado: freezed == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as String?,fechaLimite: freezed == fechaLimite ? _self.fechaLimite : fechaLimite // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [CommitmentDto].
extension CommitmentDtoPatterns on CommitmentDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CommitmentDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CommitmentDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CommitmentDto value)  $default,){
final _that = this;
switch (_that) {
case _CommitmentDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CommitmentDto value)?  $default,){
final _that = this;
switch (_that) {
case _CommitmentDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'compromiso_id')  int compromisoId, @JsonKey(name: 'sesion_id')  int sesionId,  String? descripcion,  String? estado, @JsonKey(name: 'fecha_limite')  DateTime? fechaLimite)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CommitmentDto() when $default != null:
return $default(_that.compromisoId,_that.sesionId,_that.descripcion,_that.estado,_that.fechaLimite);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'compromiso_id')  int compromisoId, @JsonKey(name: 'sesion_id')  int sesionId,  String? descripcion,  String? estado, @JsonKey(name: 'fecha_limite')  DateTime? fechaLimite)  $default,) {final _that = this;
switch (_that) {
case _CommitmentDto():
return $default(_that.compromisoId,_that.sesionId,_that.descripcion,_that.estado,_that.fechaLimite);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'compromiso_id')  int compromisoId, @JsonKey(name: 'sesion_id')  int sesionId,  String? descripcion,  String? estado, @JsonKey(name: 'fecha_limite')  DateTime? fechaLimite)?  $default,) {final _that = this;
switch (_that) {
case _CommitmentDto() when $default != null:
return $default(_that.compromisoId,_that.sesionId,_that.descripcion,_that.estado,_that.fechaLimite);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CommitmentDto extends CommitmentDto {
  const _CommitmentDto({@JsonKey(name: 'compromiso_id') required this.compromisoId, @JsonKey(name: 'sesion_id') required this.sesionId, this.descripcion, this.estado, @JsonKey(name: 'fecha_limite') this.fechaLimite}): super._();
  factory _CommitmentDto.fromJson(Map<String, dynamic> json) => _$CommitmentDtoFromJson(json);

@override@JsonKey(name: 'compromiso_id') final  int compromisoId;
@override@JsonKey(name: 'sesion_id') final  int sesionId;
@override final  String? descripcion;
@override final  String? estado;
@override@JsonKey(name: 'fecha_limite') final  DateTime? fechaLimite;

/// Create a copy of CommitmentDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CommitmentDtoCopyWith<_CommitmentDto> get copyWith => __$CommitmentDtoCopyWithImpl<_CommitmentDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CommitmentDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CommitmentDto&&(identical(other.compromisoId, compromisoId) || other.compromisoId == compromisoId)&&(identical(other.sesionId, sesionId) || other.sesionId == sesionId)&&(identical(other.descripcion, descripcion) || other.descripcion == descripcion)&&(identical(other.estado, estado) || other.estado == estado)&&(identical(other.fechaLimite, fechaLimite) || other.fechaLimite == fechaLimite));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,compromisoId,sesionId,descripcion,estado,fechaLimite);
}

@override
String toString() {
    return 'CommitmentDto(compromisoId: $compromisoId, sesionId: $sesionId, descripcion: $descripcion, estado: $estado, fechaLimite: $fechaLimite)';
}


}

/// @nodoc
abstract mixin class _$CommitmentDtoCopyWith<$Res> implements $CommitmentDtoCopyWith<$Res> {
  factory _$CommitmentDtoCopyWith(_CommitmentDto value, $Res Function(_CommitmentDto) _then) = __$CommitmentDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'compromiso_id') int compromisoId,@JsonKey(name: 'sesion_id') int sesionId, String? descripcion, String? estado,@JsonKey(name: 'fecha_limite') DateTime? fechaLimite
});




}
/// @nodoc
class __$CommitmentDtoCopyWithImpl<$Res>
    implements _$CommitmentDtoCopyWith<$Res> {
  __$CommitmentDtoCopyWithImpl(this._self, this._then);

  final _CommitmentDto _self;
  final $Res Function(_CommitmentDto) _then;

/// Create a copy of CommitmentDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? compromisoId = null,Object? sesionId = null,Object? descripcion = freezed,Object? estado = freezed,Object? fechaLimite = freezed,}) {
  return _then(_CommitmentDto(
compromisoId: null == compromisoId ? _self.compromisoId : compromisoId // ignore: cast_nullable_to_non_nullable
as int,sesionId: null == sesionId ? _self.sesionId : sesionId // ignore: cast_nullable_to_non_nullable
as int,descripcion: freezed == descripcion ? _self.descripcion : descripcion // ignore: cast_nullable_to_non_nullable
as String?,estado: freezed == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as String?,fechaLimite: freezed == fechaLimite ? _self.fechaLimite : fechaLimite // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$ProgressDto {

@JsonKey(name: 'seguimiento_id') int get seguimientoId; String? get observaciones; DateTime? get fecha;@JsonKey(name: 'referencia_cliente') String? get referenciaCliente;
/// Create a copy of ProgressDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProgressDtoCopyWith<ProgressDto> get copyWith => _$ProgressDtoCopyWithImpl<ProgressDto>(this as ProgressDto, _$identity);

  /// Serializes this ProgressDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ProgressDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProgressDto&&(identical(other.seguimientoId, _this.seguimientoId) || other.seguimientoId == _this.seguimientoId)&&(identical(other.observaciones, _this.observaciones) || other.observaciones == _this.observaciones)&&(identical(other.fecha, _this.fecha) || other.fecha == _this.fecha)&&(identical(other.referenciaCliente, _this.referenciaCliente) || other.referenciaCliente == _this.referenciaCliente));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ProgressDto;
  return Object.hash(runtimeType,_this.seguimientoId,_this.observaciones,_this.fecha,_this.referenciaCliente);
}

@override
String toString() {
  final _this = this as ProgressDto;
  return 'ProgressDto(seguimientoId: ${_this.seguimientoId}, observaciones: ${_this.observaciones}, fecha: ${_this.fecha}, referenciaCliente: ${_this.referenciaCliente})';
}


}

/// @nodoc
abstract mixin class $ProgressDtoCopyWith<$Res>  {
  factory $ProgressDtoCopyWith(ProgressDto value, $Res Function(ProgressDto) _then) = _$ProgressDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'seguimiento_id') int seguimientoId, String? observaciones, DateTime? fecha,@JsonKey(name: 'referencia_cliente') String? referenciaCliente
});




}
/// @nodoc
class _$ProgressDtoCopyWithImpl<$Res>
    implements $ProgressDtoCopyWith<$Res> {
  _$ProgressDtoCopyWithImpl(this._self, this._then);

  final ProgressDto _self;
  final $Res Function(ProgressDto) _then;

/// Create a copy of ProgressDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? seguimientoId = null,Object? observaciones = freezed,Object? fecha = freezed,Object? referenciaCliente = freezed,}) {
  return _then(ProgressDto(
seguimientoId: null == seguimientoId ? _self.seguimientoId : seguimientoId // ignore: cast_nullable_to_non_nullable
as int,observaciones: freezed == observaciones ? _self.observaciones : observaciones // ignore: cast_nullable_to_non_nullable
as String?,fecha: freezed == fecha ? _self.fecha : fecha // ignore: cast_nullable_to_non_nullable
as DateTime?,referenciaCliente: freezed == referenciaCliente ? _self.referenciaCliente : referenciaCliente // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProgressDto].
extension ProgressDtoPatterns on ProgressDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProgressDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProgressDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProgressDto value)  $default,){
final _that = this;
switch (_that) {
case _ProgressDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProgressDto value)?  $default,){
final _that = this;
switch (_that) {
case _ProgressDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'seguimiento_id')  int seguimientoId,  String? observaciones,  DateTime? fecha, @JsonKey(name: 'referencia_cliente')  String? referenciaCliente)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProgressDto() when $default != null:
return $default(_that.seguimientoId,_that.observaciones,_that.fecha,_that.referenciaCliente);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'seguimiento_id')  int seguimientoId,  String? observaciones,  DateTime? fecha, @JsonKey(name: 'referencia_cliente')  String? referenciaCliente)  $default,) {final _that = this;
switch (_that) {
case _ProgressDto():
return $default(_that.seguimientoId,_that.observaciones,_that.fecha,_that.referenciaCliente);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'seguimiento_id')  int seguimientoId,  String? observaciones,  DateTime? fecha, @JsonKey(name: 'referencia_cliente')  String? referenciaCliente)?  $default,) {final _that = this;
switch (_that) {
case _ProgressDto() when $default != null:
return $default(_that.seguimientoId,_that.observaciones,_that.fecha,_that.referenciaCliente);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProgressDto extends ProgressDto {
  const _ProgressDto({@JsonKey(name: 'seguimiento_id') required this.seguimientoId, this.observaciones, this.fecha, @JsonKey(name: 'referencia_cliente') this.referenciaCliente}): super._();
  factory _ProgressDto.fromJson(Map<String, dynamic> json) => _$ProgressDtoFromJson(json);

@override@JsonKey(name: 'seguimiento_id') final  int seguimientoId;
@override final  String? observaciones;
@override final  DateTime? fecha;
@override@JsonKey(name: 'referencia_cliente') final  String? referenciaCliente;

/// Create a copy of ProgressDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProgressDtoCopyWith<_ProgressDto> get copyWith => __$ProgressDtoCopyWithImpl<_ProgressDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProgressDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProgressDto&&(identical(other.seguimientoId, seguimientoId) || other.seguimientoId == seguimientoId)&&(identical(other.observaciones, observaciones) || other.observaciones == observaciones)&&(identical(other.fecha, fecha) || other.fecha == fecha)&&(identical(other.referenciaCliente, referenciaCliente) || other.referenciaCliente == referenciaCliente));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,seguimientoId,observaciones,fecha,referenciaCliente);
}

@override
String toString() {
    return 'ProgressDto(seguimientoId: $seguimientoId, observaciones: $observaciones, fecha: $fecha, referenciaCliente: $referenciaCliente)';
}


}

/// @nodoc
abstract mixin class _$ProgressDtoCopyWith<$Res> implements $ProgressDtoCopyWith<$Res> {
  factory _$ProgressDtoCopyWith(_ProgressDto value, $Res Function(_ProgressDto) _then) = __$ProgressDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'seguimiento_id') int seguimientoId, String? observaciones, DateTime? fecha,@JsonKey(name: 'referencia_cliente') String? referenciaCliente
});




}
/// @nodoc
class __$ProgressDtoCopyWithImpl<$Res>
    implements _$ProgressDtoCopyWith<$Res> {
  __$ProgressDtoCopyWithImpl(this._self, this._then);

  final _ProgressDto _self;
  final $Res Function(_ProgressDto) _then;

/// Create a copy of ProgressDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? seguimientoId = null,Object? observaciones = freezed,Object? fecha = freezed,Object? referenciaCliente = freezed,}) {
  return _then(_ProgressDto(
seguimientoId: null == seguimientoId ? _self.seguimientoId : seguimientoId // ignore: cast_nullable_to_non_nullable
as int,observaciones: freezed == observaciones ? _self.observaciones : observaciones // ignore: cast_nullable_to_non_nullable
as String?,fecha: freezed == fecha ? _self.fecha : fecha // ignore: cast_nullable_to_non_nullable
as DateTime?,referenciaCliente: freezed == referenciaCliente ? _self.referenciaCliente : referenciaCliente // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$SyncResultDto {

 List<ProgressDto> get avances; List<CommitmentDto> get compromisos; List<String> get errores;
/// Create a copy of SyncResultDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SyncResultDtoCopyWith<SyncResultDto> get copyWith => _$SyncResultDtoCopyWithImpl<SyncResultDto>(this as SyncResultDto, _$identity);

  /// Serializes this SyncResultDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SyncResultDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncResultDto&&const DeepCollectionEquality().equals(other.avances, _this.avances)&&const DeepCollectionEquality().equals(other.compromisos, _this.compromisos)&&const DeepCollectionEquality().equals(other.errores, _this.errores));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SyncResultDto;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.avances),const DeepCollectionEquality().hash(_this.compromisos),const DeepCollectionEquality().hash(_this.errores));
}

@override
String toString() {
  final _this = this as SyncResultDto;
  return 'SyncResultDto(avances: ${_this.avances}, compromisos: ${_this.compromisos}, errores: ${_this.errores})';
}


}

/// @nodoc
abstract mixin class $SyncResultDtoCopyWith<$Res>  {
  factory $SyncResultDtoCopyWith(SyncResultDto value, $Res Function(SyncResultDto) _then) = _$SyncResultDtoCopyWithImpl;
@useResult
$Res call({
 List<ProgressDto> avances, List<CommitmentDto> compromisos, List<String> errores
});




}
/// @nodoc
class _$SyncResultDtoCopyWithImpl<$Res>
    implements $SyncResultDtoCopyWith<$Res> {
  _$SyncResultDtoCopyWithImpl(this._self, this._then);

  final SyncResultDto _self;
  final $Res Function(SyncResultDto) _then;

/// Create a copy of SyncResultDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? avances = null,Object? compromisos = null,Object? errores = null,}) {
  return _then(SyncResultDto(
avances: null == avances ? _self.avances : avances // ignore: cast_nullable_to_non_nullable
as List<ProgressDto>,compromisos: null == compromisos ? _self.compromisos : compromisos // ignore: cast_nullable_to_non_nullable
as List<CommitmentDto>,errores: null == errores ? _self.errores : errores // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [SyncResultDto].
extension SyncResultDtoPatterns on SyncResultDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SyncResultDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SyncResultDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SyncResultDto value)  $default,){
final _that = this;
switch (_that) {
case _SyncResultDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SyncResultDto value)?  $default,){
final _that = this;
switch (_that) {
case _SyncResultDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<ProgressDto> avances,  List<CommitmentDto> compromisos,  List<String> errores)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SyncResultDto() when $default != null:
return $default(_that.avances,_that.compromisos,_that.errores);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<ProgressDto> avances,  List<CommitmentDto> compromisos,  List<String> errores)  $default,) {final _that = this;
switch (_that) {
case _SyncResultDto():
return $default(_that.avances,_that.compromisos,_that.errores);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<ProgressDto> avances,  List<CommitmentDto> compromisos,  List<String> errores)?  $default,) {final _that = this;
switch (_that) {
case _SyncResultDto() when $default != null:
return $default(_that.avances,_that.compromisos,_that.errores);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SyncResultDto implements SyncResultDto {
  const _SyncResultDto({ List<ProgressDto> avances = const <ProgressDto>[],  List<CommitmentDto> compromisos = const <CommitmentDto>[],  List<String> errores = const <String>[]}): _avances = avances,_compromisos = compromisos,_errores = errores;
  factory _SyncResultDto.fromJson(Map<String, dynamic> json) => _$SyncResultDtoFromJson(json);

 final  List<ProgressDto> _avances;
@override@JsonKey() List<ProgressDto> get avances {
  if (_avances is EqualUnmodifiableListView) return _avances;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_avances);
}

 final  List<CommitmentDto> _compromisos;
@override@JsonKey() List<CommitmentDto> get compromisos {
  if (_compromisos is EqualUnmodifiableListView) return _compromisos;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_compromisos);
}

 final  List<String> _errores;
@override@JsonKey() List<String> get errores {
  if (_errores is EqualUnmodifiableListView) return _errores;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_errores);
}


/// Create a copy of SyncResultDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SyncResultDtoCopyWith<_SyncResultDto> get copyWith => __$SyncResultDtoCopyWithImpl<_SyncResultDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SyncResultDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SyncResultDto&&const DeepCollectionEquality().equals(other.avances, _avances)&&const DeepCollectionEquality().equals(other.compromisos, _compromisos)&&const DeepCollectionEquality().equals(other.errores, _errores));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_avances),const DeepCollectionEquality().hash(_compromisos),const DeepCollectionEquality().hash(_errores));
}

@override
String toString() {
    return 'SyncResultDto(avances: $avances, compromisos: $compromisos, errores: $errores)';
}


}

/// @nodoc
abstract mixin class _$SyncResultDtoCopyWith<$Res> implements $SyncResultDtoCopyWith<$Res> {
  factory _$SyncResultDtoCopyWith(_SyncResultDto value, $Res Function(_SyncResultDto) _then) = __$SyncResultDtoCopyWithImpl;
@override @useResult
$Res call({
 List<ProgressDto> avances, List<CommitmentDto> compromisos, List<String> errores
});




}
/// @nodoc
class __$SyncResultDtoCopyWithImpl<$Res>
    implements _$SyncResultDtoCopyWith<$Res> {
  __$SyncResultDtoCopyWithImpl(this._self, this._then);

  final _SyncResultDto _self;
  final $Res Function(_SyncResultDto) _then;

/// Create a copy of SyncResultDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? avances = null,Object? compromisos = null,Object? errores = null,}) {
  return _then(_SyncResultDto(
avances: null == avances ? _self._avances : avances // ignore: cast_nullable_to_non_nullable
as List<ProgressDto>,compromisos: null == compromisos ? _self._compromisos : compromisos // ignore: cast_nullable_to_non_nullable
as List<CommitmentDto>,errores: null == errores ? _self._errores : errores // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
