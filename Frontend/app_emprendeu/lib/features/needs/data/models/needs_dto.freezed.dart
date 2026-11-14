// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'needs_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NeedCategoryDto {

@JsonKey(name: 'necesidad_id') int get necesidadId; String get nombre; String? get descripcion;
/// Create a copy of NeedCategoryDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NeedCategoryDtoCopyWith<NeedCategoryDto> get copyWith => _$NeedCategoryDtoCopyWithImpl<NeedCategoryDto>(this as NeedCategoryDto, _$identity);

  /// Serializes this NeedCategoryDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as NeedCategoryDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NeedCategoryDto&&(identical(other.necesidadId, _this.necesidadId) || other.necesidadId == _this.necesidadId)&&(identical(other.nombre, _this.nombre) || other.nombre == _this.nombre)&&(identical(other.descripcion, _this.descripcion) || other.descripcion == _this.descripcion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as NeedCategoryDto;
  return Object.hash(runtimeType,_this.necesidadId,_this.nombre,_this.descripcion);
}

@override
String toString() {
  final _this = this as NeedCategoryDto;
  return 'NeedCategoryDto(necesidadId: ${_this.necesidadId}, nombre: ${_this.nombre}, descripcion: ${_this.descripcion})';
}


}

/// @nodoc
abstract mixin class $NeedCategoryDtoCopyWith<$Res>  {
  factory $NeedCategoryDtoCopyWith(NeedCategoryDto value, $Res Function(NeedCategoryDto) _then) = _$NeedCategoryDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'necesidad_id') int necesidadId, String nombre, String? descripcion
});




}
/// @nodoc
class _$NeedCategoryDtoCopyWithImpl<$Res>
    implements $NeedCategoryDtoCopyWith<$Res> {
  _$NeedCategoryDtoCopyWithImpl(this._self, this._then);

  final NeedCategoryDto _self;
  final $Res Function(NeedCategoryDto) _then;

/// Create a copy of NeedCategoryDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? necesidadId = null,Object? nombre = null,Object? descripcion = freezed,}) {
  return _then(NeedCategoryDto(
necesidadId: null == necesidadId ? _self.necesidadId : necesidadId // ignore: cast_nullable_to_non_nullable
as int,nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,descripcion: freezed == descripcion ? _self.descripcion : descripcion // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [NeedCategoryDto].
extension NeedCategoryDtoPatterns on NeedCategoryDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NeedCategoryDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NeedCategoryDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NeedCategoryDto value)  $default,){
final _that = this;
switch (_that) {
case _NeedCategoryDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NeedCategoryDto value)?  $default,){
final _that = this;
switch (_that) {
case _NeedCategoryDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'necesidad_id')  int necesidadId,  String nombre,  String? descripcion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NeedCategoryDto() when $default != null:
return $default(_that.necesidadId,_that.nombre,_that.descripcion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'necesidad_id')  int necesidadId,  String nombre,  String? descripcion)  $default,) {final _that = this;
switch (_that) {
case _NeedCategoryDto():
return $default(_that.necesidadId,_that.nombre,_that.descripcion);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'necesidad_id')  int necesidadId,  String nombre,  String? descripcion)?  $default,) {final _that = this;
switch (_that) {
case _NeedCategoryDto() when $default != null:
return $default(_that.necesidadId,_that.nombre,_that.descripcion);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NeedCategoryDto extends NeedCategoryDto {
  const _NeedCategoryDto({@JsonKey(name: 'necesidad_id') required this.necesidadId, required this.nombre, this.descripcion}): super._();
  factory _NeedCategoryDto.fromJson(Map<String, dynamic> json) => _$NeedCategoryDtoFromJson(json);

@override@JsonKey(name: 'necesidad_id') final  int necesidadId;
@override final  String nombre;
@override final  String? descripcion;

/// Create a copy of NeedCategoryDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NeedCategoryDtoCopyWith<_NeedCategoryDto> get copyWith => __$NeedCategoryDtoCopyWithImpl<_NeedCategoryDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NeedCategoryDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _NeedCategoryDto&&(identical(other.necesidadId, necesidadId) || other.necesidadId == necesidadId)&&(identical(other.nombre, nombre) || other.nombre == nombre)&&(identical(other.descripcion, descripcion) || other.descripcion == descripcion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,necesidadId,nombre,descripcion);
}

@override
String toString() {
    return 'NeedCategoryDto(necesidadId: $necesidadId, nombre: $nombre, descripcion: $descripcion)';
}


}

/// @nodoc
abstract mixin class _$NeedCategoryDtoCopyWith<$Res> implements $NeedCategoryDtoCopyWith<$Res> {
  factory _$NeedCategoryDtoCopyWith(_NeedCategoryDto value, $Res Function(_NeedCategoryDto) _then) = __$NeedCategoryDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'necesidad_id') int necesidadId, String nombre, String? descripcion
});




}
/// @nodoc
class __$NeedCategoryDtoCopyWithImpl<$Res>
    implements _$NeedCategoryDtoCopyWith<$Res> {
  __$NeedCategoryDtoCopyWithImpl(this._self, this._then);

  final _NeedCategoryDto _self;
  final $Res Function(_NeedCategoryDto) _then;

/// Create a copy of NeedCategoryDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? necesidadId = null,Object? nombre = null,Object? descripcion = freezed,}) {
  return _then(_NeedCategoryDto(
necesidadId: null == necesidadId ? _self.necesidadId : necesidadId // ignore: cast_nullable_to_non_nullable
as int,nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,descripcion: freezed == descripcion ? _self.descripcion : descripcion // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$VentureNeedDto {

@JsonKey(name: 'emprendimiento_necesidad_id') int get id;@JsonKey(name: 'necesidad_id') int get necesidadId; String get necesidad; String? get estado; String? get prioridad; String get tipo; String? get descripcion;@JsonKey(name: 'fecha_detectada') DateTime? get fechaDetectada;@JsonKey(name: 'fecha_resuelta') DateTime? get fechaResuelta;
/// Create a copy of VentureNeedDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VentureNeedDtoCopyWith<VentureNeedDto> get copyWith => _$VentureNeedDtoCopyWithImpl<VentureNeedDto>(this as VentureNeedDto, _$identity);

  /// Serializes this VentureNeedDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as VentureNeedDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VentureNeedDto&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.necesidadId, _this.necesidadId) || other.necesidadId == _this.necesidadId)&&(identical(other.necesidad, _this.necesidad) || other.necesidad == _this.necesidad)&&(identical(other.estado, _this.estado) || other.estado == _this.estado)&&(identical(other.prioridad, _this.prioridad) || other.prioridad == _this.prioridad)&&(identical(other.tipo, _this.tipo) || other.tipo == _this.tipo)&&(identical(other.descripcion, _this.descripcion) || other.descripcion == _this.descripcion)&&(identical(other.fechaDetectada, _this.fechaDetectada) || other.fechaDetectada == _this.fechaDetectada)&&(identical(other.fechaResuelta, _this.fechaResuelta) || other.fechaResuelta == _this.fechaResuelta));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as VentureNeedDto;
  return Object.hash(runtimeType,_this.id,_this.necesidadId,_this.necesidad,_this.estado,_this.prioridad,_this.tipo,_this.descripcion,_this.fechaDetectada,_this.fechaResuelta);
}

@override
String toString() {
  final _this = this as VentureNeedDto;
  return 'VentureNeedDto(id: ${_this.id}, necesidadId: ${_this.necesidadId}, necesidad: ${_this.necesidad}, estado: ${_this.estado}, prioridad: ${_this.prioridad}, tipo: ${_this.tipo}, descripcion: ${_this.descripcion}, fechaDetectada: ${_this.fechaDetectada}, fechaResuelta: ${_this.fechaResuelta})';
}


}

/// @nodoc
abstract mixin class $VentureNeedDtoCopyWith<$Res>  {
  factory $VentureNeedDtoCopyWith(VentureNeedDto value, $Res Function(VentureNeedDto) _then) = _$VentureNeedDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'emprendimiento_necesidad_id') int id,@JsonKey(name: 'necesidad_id') int necesidadId, String necesidad, String? estado, String? prioridad, String tipo, String? descripcion,@JsonKey(name: 'fecha_detectada') DateTime? fechaDetectada,@JsonKey(name: 'fecha_resuelta') DateTime? fechaResuelta
});




}
/// @nodoc
class _$VentureNeedDtoCopyWithImpl<$Res>
    implements $VentureNeedDtoCopyWith<$Res> {
  _$VentureNeedDtoCopyWithImpl(this._self, this._then);

  final VentureNeedDto _self;
  final $Res Function(VentureNeedDto) _then;

/// Create a copy of VentureNeedDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? necesidadId = null,Object? necesidad = null,Object? estado = freezed,Object? prioridad = freezed,Object? tipo = null,Object? descripcion = freezed,Object? fechaDetectada = freezed,Object? fechaResuelta = freezed,}) {
  return _then(VentureNeedDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,necesidadId: null == necesidadId ? _self.necesidadId : necesidadId // ignore: cast_nullable_to_non_nullable
as int,necesidad: null == necesidad ? _self.necesidad : necesidad // ignore: cast_nullable_to_non_nullable
as String,estado: freezed == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as String?,prioridad: freezed == prioridad ? _self.prioridad : prioridad // ignore: cast_nullable_to_non_nullable
as String?,tipo: null == tipo ? _self.tipo : tipo // ignore: cast_nullable_to_non_nullable
as String,descripcion: freezed == descripcion ? _self.descripcion : descripcion // ignore: cast_nullable_to_non_nullable
as String?,fechaDetectada: freezed == fechaDetectada ? _self.fechaDetectada : fechaDetectada // ignore: cast_nullable_to_non_nullable
as DateTime?,fechaResuelta: freezed == fechaResuelta ? _self.fechaResuelta : fechaResuelta // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [VentureNeedDto].
extension VentureNeedDtoPatterns on VentureNeedDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VentureNeedDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VentureNeedDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VentureNeedDto value)  $default,){
final _that = this;
switch (_that) {
case _VentureNeedDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VentureNeedDto value)?  $default,){
final _that = this;
switch (_that) {
case _VentureNeedDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'emprendimiento_necesidad_id')  int id, @JsonKey(name: 'necesidad_id')  int necesidadId,  String necesidad,  String? estado,  String? prioridad,  String tipo,  String? descripcion, @JsonKey(name: 'fecha_detectada')  DateTime? fechaDetectada, @JsonKey(name: 'fecha_resuelta')  DateTime? fechaResuelta)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VentureNeedDto() when $default != null:
return $default(_that.id,_that.necesidadId,_that.necesidad,_that.estado,_that.prioridad,_that.tipo,_that.descripcion,_that.fechaDetectada,_that.fechaResuelta);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'emprendimiento_necesidad_id')  int id, @JsonKey(name: 'necesidad_id')  int necesidadId,  String necesidad,  String? estado,  String? prioridad,  String tipo,  String? descripcion, @JsonKey(name: 'fecha_detectada')  DateTime? fechaDetectada, @JsonKey(name: 'fecha_resuelta')  DateTime? fechaResuelta)  $default,) {final _that = this;
switch (_that) {
case _VentureNeedDto():
return $default(_that.id,_that.necesidadId,_that.necesidad,_that.estado,_that.prioridad,_that.tipo,_that.descripcion,_that.fechaDetectada,_that.fechaResuelta);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'emprendimiento_necesidad_id')  int id, @JsonKey(name: 'necesidad_id')  int necesidadId,  String necesidad,  String? estado,  String? prioridad,  String tipo,  String? descripcion, @JsonKey(name: 'fecha_detectada')  DateTime? fechaDetectada, @JsonKey(name: 'fecha_resuelta')  DateTime? fechaResuelta)?  $default,) {final _that = this;
switch (_that) {
case _VentureNeedDto() when $default != null:
return $default(_that.id,_that.necesidadId,_that.necesidad,_that.estado,_that.prioridad,_that.tipo,_that.descripcion,_that.fechaDetectada,_that.fechaResuelta);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VentureNeedDto extends VentureNeedDto {
  const _VentureNeedDto({@JsonKey(name: 'emprendimiento_necesidad_id') required this.id, @JsonKey(name: 'necesidad_id') required this.necesidadId, required this.necesidad, this.estado, this.prioridad, this.tipo = 'necesidad', this.descripcion, @JsonKey(name: 'fecha_detectada') this.fechaDetectada, @JsonKey(name: 'fecha_resuelta') this.fechaResuelta}): super._();
  factory _VentureNeedDto.fromJson(Map<String, dynamic> json) => _$VentureNeedDtoFromJson(json);

@override@JsonKey(name: 'emprendimiento_necesidad_id') final  int id;
@override@JsonKey(name: 'necesidad_id') final  int necesidadId;
@override final  String necesidad;
@override final  String? estado;
@override final  String? prioridad;
@override@JsonKey() final  String tipo;
@override final  String? descripcion;
@override@JsonKey(name: 'fecha_detectada') final  DateTime? fechaDetectada;
@override@JsonKey(name: 'fecha_resuelta') final  DateTime? fechaResuelta;

/// Create a copy of VentureNeedDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VentureNeedDtoCopyWith<_VentureNeedDto> get copyWith => __$VentureNeedDtoCopyWithImpl<_VentureNeedDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VentureNeedDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _VentureNeedDto&&(identical(other.id, id) || other.id == id)&&(identical(other.necesidadId, necesidadId) || other.necesidadId == necesidadId)&&(identical(other.necesidad, necesidad) || other.necesidad == necesidad)&&(identical(other.estado, estado) || other.estado == estado)&&(identical(other.prioridad, prioridad) || other.prioridad == prioridad)&&(identical(other.tipo, tipo) || other.tipo == tipo)&&(identical(other.descripcion, descripcion) || other.descripcion == descripcion)&&(identical(other.fechaDetectada, fechaDetectada) || other.fechaDetectada == fechaDetectada)&&(identical(other.fechaResuelta, fechaResuelta) || other.fechaResuelta == fechaResuelta));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,necesidadId,necesidad,estado,prioridad,tipo,descripcion,fechaDetectada,fechaResuelta);
}

@override
String toString() {
    return 'VentureNeedDto(id: $id, necesidadId: $necesidadId, necesidad: $necesidad, estado: $estado, prioridad: $prioridad, tipo: $tipo, descripcion: $descripcion, fechaDetectada: $fechaDetectada, fechaResuelta: $fechaResuelta)';
}


}

/// @nodoc
abstract mixin class _$VentureNeedDtoCopyWith<$Res> implements $VentureNeedDtoCopyWith<$Res> {
  factory _$VentureNeedDtoCopyWith(_VentureNeedDto value, $Res Function(_VentureNeedDto) _then) = __$VentureNeedDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'emprendimiento_necesidad_id') int id,@JsonKey(name: 'necesidad_id') int necesidadId, String necesidad, String? estado, String? prioridad, String tipo, String? descripcion,@JsonKey(name: 'fecha_detectada') DateTime? fechaDetectada,@JsonKey(name: 'fecha_resuelta') DateTime? fechaResuelta
});




}
/// @nodoc
class __$VentureNeedDtoCopyWithImpl<$Res>
    implements _$VentureNeedDtoCopyWith<$Res> {
  __$VentureNeedDtoCopyWithImpl(this._self, this._then);

  final _VentureNeedDto _self;
  final $Res Function(_VentureNeedDto) _then;

/// Create a copy of VentureNeedDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? necesidadId = null,Object? necesidad = null,Object? estado = freezed,Object? prioridad = freezed,Object? tipo = null,Object? descripcion = freezed,Object? fechaDetectada = freezed,Object? fechaResuelta = freezed,}) {
  return _then(_VentureNeedDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,necesidadId: null == necesidadId ? _self.necesidadId : necesidadId // ignore: cast_nullable_to_non_nullable
as int,necesidad: null == necesidad ? _self.necesidad : necesidad // ignore: cast_nullable_to_non_nullable
as String,estado: freezed == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as String?,prioridad: freezed == prioridad ? _self.prioridad : prioridad // ignore: cast_nullable_to_non_nullable
as String?,tipo: null == tipo ? _self.tipo : tipo // ignore: cast_nullable_to_non_nullable
as String,descripcion: freezed == descripcion ? _self.descripcion : descripcion // ignore: cast_nullable_to_non_nullable
as String?,fechaDetectada: freezed == fechaDetectada ? _self.fechaDetectada : fechaDetectada // ignore: cast_nullable_to_non_nullable
as DateTime?,fechaResuelta: freezed == fechaResuelta ? _self.fechaResuelta : fechaResuelta // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
