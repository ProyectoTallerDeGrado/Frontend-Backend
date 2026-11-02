// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'need_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$VentureNeedDto {

@JsonKey(name: 'emprendimiento_necesidad_id') int get id; String get necesidad; String? get estado; String? get prioridad;@JsonKey(name: 'fecha_detectada') DateTime? get fechaDetectada;@JsonKey(name: 'fecha_resuelta') DateTime? get fechaResuelta;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VentureNeedDto&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.necesidad, _this.necesidad) || other.necesidad == _this.necesidad)&&(identical(other.estado, _this.estado) || other.estado == _this.estado)&&(identical(other.prioridad, _this.prioridad) || other.prioridad == _this.prioridad)&&(identical(other.fechaDetectada, _this.fechaDetectada) || other.fechaDetectada == _this.fechaDetectada)&&(identical(other.fechaResuelta, _this.fechaResuelta) || other.fechaResuelta == _this.fechaResuelta));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as VentureNeedDto;
  return Object.hash(runtimeType,_this.id,_this.necesidad,_this.estado,_this.prioridad,_this.fechaDetectada,_this.fechaResuelta);
}

@override
String toString() {
  final _this = this as VentureNeedDto;
  return 'VentureNeedDto(id: ${_this.id}, necesidad: ${_this.necesidad}, estado: ${_this.estado}, prioridad: ${_this.prioridad}, fechaDetectada: ${_this.fechaDetectada}, fechaResuelta: ${_this.fechaResuelta})';
}


}

/// @nodoc
abstract mixin class $VentureNeedDtoCopyWith<$Res>  {
  factory $VentureNeedDtoCopyWith(VentureNeedDto value, $Res Function(VentureNeedDto) _then) = _$VentureNeedDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'emprendimiento_necesidad_id') int id, String necesidad, String? estado, String? prioridad,@JsonKey(name: 'fecha_detectada') DateTime? fechaDetectada,@JsonKey(name: 'fecha_resuelta') DateTime? fechaResuelta
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? necesidad = null,Object? estado = freezed,Object? prioridad = freezed,Object? fechaDetectada = freezed,Object? fechaResuelta = freezed,}) {
  return _then(VentureNeedDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,necesidad: null == necesidad ? _self.necesidad : necesidad // ignore: cast_nullable_to_non_nullable
as String,estado: freezed == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as String?,prioridad: freezed == prioridad ? _self.prioridad : prioridad // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'emprendimiento_necesidad_id')  int id,  String necesidad,  String? estado,  String? prioridad, @JsonKey(name: 'fecha_detectada')  DateTime? fechaDetectada, @JsonKey(name: 'fecha_resuelta')  DateTime? fechaResuelta)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VentureNeedDto() when $default != null:
return $default(_that.id,_that.necesidad,_that.estado,_that.prioridad,_that.fechaDetectada,_that.fechaResuelta);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'emprendimiento_necesidad_id')  int id,  String necesidad,  String? estado,  String? prioridad, @JsonKey(name: 'fecha_detectada')  DateTime? fechaDetectada, @JsonKey(name: 'fecha_resuelta')  DateTime? fechaResuelta)  $default,) {final _that = this;
switch (_that) {
case _VentureNeedDto():
return $default(_that.id,_that.necesidad,_that.estado,_that.prioridad,_that.fechaDetectada,_that.fechaResuelta);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'emprendimiento_necesidad_id')  int id,  String necesidad,  String? estado,  String? prioridad, @JsonKey(name: 'fecha_detectada')  DateTime? fechaDetectada, @JsonKey(name: 'fecha_resuelta')  DateTime? fechaResuelta)?  $default,) {final _that = this;
switch (_that) {
case _VentureNeedDto() when $default != null:
return $default(_that.id,_that.necesidad,_that.estado,_that.prioridad,_that.fechaDetectada,_that.fechaResuelta);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VentureNeedDto extends VentureNeedDto {
  const _VentureNeedDto({@JsonKey(name: 'emprendimiento_necesidad_id') required this.id, required this.necesidad, this.estado, this.prioridad, @JsonKey(name: 'fecha_detectada') this.fechaDetectada, @JsonKey(name: 'fecha_resuelta') this.fechaResuelta}): super._();
  factory _VentureNeedDto.fromJson(Map<String, dynamic> json) => _$VentureNeedDtoFromJson(json);

@override@JsonKey(name: 'emprendimiento_necesidad_id') final  int id;
@override final  String necesidad;
@override final  String? estado;
@override final  String? prioridad;
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
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _VentureNeedDto&&(identical(other.id, id) || other.id == id)&&(identical(other.necesidad, necesidad) || other.necesidad == necesidad)&&(identical(other.estado, estado) || other.estado == estado)&&(identical(other.prioridad, prioridad) || other.prioridad == prioridad)&&(identical(other.fechaDetectada, fechaDetectada) || other.fechaDetectada == fechaDetectada)&&(identical(other.fechaResuelta, fechaResuelta) || other.fechaResuelta == fechaResuelta));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,necesidad,estado,prioridad,fechaDetectada,fechaResuelta);
}

@override
String toString() {
    return 'VentureNeedDto(id: $id, necesidad: $necesidad, estado: $estado, prioridad: $prioridad, fechaDetectada: $fechaDetectada, fechaResuelta: $fechaResuelta)';
}


}

/// @nodoc
abstract mixin class _$VentureNeedDtoCopyWith<$Res> implements $VentureNeedDtoCopyWith<$Res> {
  factory _$VentureNeedDtoCopyWith(_VentureNeedDto value, $Res Function(_VentureNeedDto) _then) = __$VentureNeedDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'emprendimiento_necesidad_id') int id, String necesidad, String? estado, String? prioridad,@JsonKey(name: 'fecha_detectada') DateTime? fechaDetectada,@JsonKey(name: 'fecha_resuelta') DateTime? fechaResuelta
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? necesidad = null,Object? estado = freezed,Object? prioridad = freezed,Object? fechaDetectada = freezed,Object? fechaResuelta = freezed,}) {
  return _then(_VentureNeedDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,necesidad: null == necesidad ? _self.necesidad : necesidad // ignore: cast_nullable_to_non_nullable
as String,estado: freezed == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as String?,prioridad: freezed == prioridad ? _self.prioridad : prioridad // ignore: cast_nullable_to_non_nullable
as String?,fechaDetectada: freezed == fechaDetectada ? _self.fechaDetectada : fechaDetectada // ignore: cast_nullable_to_non_nullable
as DateTime?,fechaResuelta: freezed == fechaResuelta ? _self.fechaResuelta : fechaResuelta // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$NeedCatalogDto {

 String get nombre;
/// Create a copy of NeedCatalogDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NeedCatalogDtoCopyWith<NeedCatalogDto> get copyWith => _$NeedCatalogDtoCopyWithImpl<NeedCatalogDto>(this as NeedCatalogDto, _$identity);

  /// Serializes this NeedCatalogDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as NeedCatalogDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NeedCatalogDto&&(identical(other.nombre, _this.nombre) || other.nombre == _this.nombre));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as NeedCatalogDto;
  return Object.hash(runtimeType,_this.nombre);
}

@override
String toString() {
  final _this = this as NeedCatalogDto;
  return 'NeedCatalogDto(nombre: ${_this.nombre})';
}


}

/// @nodoc
abstract mixin class $NeedCatalogDtoCopyWith<$Res>  {
  factory $NeedCatalogDtoCopyWith(NeedCatalogDto value, $Res Function(NeedCatalogDto) _then) = _$NeedCatalogDtoCopyWithImpl;
@useResult
$Res call({
 String nombre
});




}
/// @nodoc
class _$NeedCatalogDtoCopyWithImpl<$Res>
    implements $NeedCatalogDtoCopyWith<$Res> {
  _$NeedCatalogDtoCopyWithImpl(this._self, this._then);

  final NeedCatalogDto _self;
  final $Res Function(NeedCatalogDto) _then;

/// Create a copy of NeedCatalogDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? nombre = null,}) {
  return _then(NeedCatalogDto(
nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [NeedCatalogDto].
extension NeedCatalogDtoPatterns on NeedCatalogDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NeedCatalogDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NeedCatalogDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NeedCatalogDto value)  $default,){
final _that = this;
switch (_that) {
case _NeedCatalogDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NeedCatalogDto value)?  $default,){
final _that = this;
switch (_that) {
case _NeedCatalogDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String nombre)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NeedCatalogDto() when $default != null:
return $default(_that.nombre);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String nombre)  $default,) {final _that = this;
switch (_that) {
case _NeedCatalogDto():
return $default(_that.nombre);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String nombre)?  $default,) {final _that = this;
switch (_that) {
case _NeedCatalogDto() when $default != null:
return $default(_that.nombre);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NeedCatalogDto implements NeedCatalogDto {
  const _NeedCatalogDto({required this.nombre});
  factory _NeedCatalogDto.fromJson(Map<String, dynamic> json) => _$NeedCatalogDtoFromJson(json);

@override final  String nombre;

/// Create a copy of NeedCatalogDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NeedCatalogDtoCopyWith<_NeedCatalogDto> get copyWith => __$NeedCatalogDtoCopyWithImpl<_NeedCatalogDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NeedCatalogDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _NeedCatalogDto&&(identical(other.nombre, nombre) || other.nombre == nombre));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,nombre);
}

@override
String toString() {
    return 'NeedCatalogDto(nombre: $nombre)';
}


}

/// @nodoc
abstract mixin class _$NeedCatalogDtoCopyWith<$Res> implements $NeedCatalogDtoCopyWith<$Res> {
  factory _$NeedCatalogDtoCopyWith(_NeedCatalogDto value, $Res Function(_NeedCatalogDto) _then) = __$NeedCatalogDtoCopyWithImpl;
@override @useResult
$Res call({
 String nombre
});




}
/// @nodoc
class __$NeedCatalogDtoCopyWithImpl<$Res>
    implements _$NeedCatalogDtoCopyWith<$Res> {
  __$NeedCatalogDtoCopyWithImpl(this._self, this._then);

  final _NeedCatalogDto _self;
  final $Res Function(_NeedCatalogDto) _then;

/// Create a copy of NeedCatalogDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? nombre = null,}) {
  return _then(_NeedCatalogDto(
nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
