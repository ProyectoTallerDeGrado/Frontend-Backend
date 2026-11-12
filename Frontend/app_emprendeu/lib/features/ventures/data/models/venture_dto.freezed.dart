// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'venture_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StageDto {

 String get nombre;
/// Create a copy of StageDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StageDtoCopyWith<StageDto> get copyWith => _$StageDtoCopyWithImpl<StageDto>(this as StageDto, _$identity);

  /// Serializes this StageDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as StageDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StageDto&&(identical(other.nombre, _this.nombre) || other.nombre == _this.nombre));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as StageDto;
  return Object.hash(runtimeType,_this.nombre);
}

@override
String toString() {
  final _this = this as StageDto;
  return 'StageDto(nombre: ${_this.nombre})';
}


}

/// @nodoc
abstract mixin class $StageDtoCopyWith<$Res>  {
  factory $StageDtoCopyWith(StageDto value, $Res Function(StageDto) _then) = _$StageDtoCopyWithImpl;
@useResult
$Res call({
 String nombre
});




}
/// @nodoc
class _$StageDtoCopyWithImpl<$Res>
    implements $StageDtoCopyWith<$Res> {
  _$StageDtoCopyWithImpl(this._self, this._then);

  final StageDto _self;
  final $Res Function(StageDto) _then;

/// Create a copy of StageDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? nombre = null,}) {
  return _then(StageDto(
nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [StageDto].
extension StageDtoPatterns on StageDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StageDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StageDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StageDto value)  $default,){
final _that = this;
switch (_that) {
case _StageDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StageDto value)?  $default,){
final _that = this;
switch (_that) {
case _StageDto() when $default != null:
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
case _StageDto() when $default != null:
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
case _StageDto():
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
case _StageDto() when $default != null:
return $default(_that.nombre);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StageDto implements StageDto {
  const _StageDto({required this.nombre});
  factory _StageDto.fromJson(Map<String, dynamic> json) => _$StageDtoFromJson(json);

@override final  String nombre;

/// Create a copy of StageDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StageDtoCopyWith<_StageDto> get copyWith => __$StageDtoCopyWithImpl<_StageDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StageDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _StageDto&&(identical(other.nombre, nombre) || other.nombre == nombre));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,nombre);
}

@override
String toString() {
    return 'StageDto(nombre: $nombre)';
}


}

/// @nodoc
abstract mixin class _$StageDtoCopyWith<$Res> implements $StageDtoCopyWith<$Res> {
  factory _$StageDtoCopyWith(_StageDto value, $Res Function(_StageDto) _then) = __$StageDtoCopyWithImpl;
@override @useResult
$Res call({
 String nombre
});




}
/// @nodoc
class __$StageDtoCopyWithImpl<$Res>
    implements _$StageDtoCopyWith<$Res> {
  __$StageDtoCopyWithImpl(this._self, this._then);

  final _StageDto _self;
  final $Res Function(_StageDto) _then;

/// Create a copy of StageDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? nombre = null,}) {
  return _then(_StageDto(
nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$MemberDto {

@JsonKey(name: 'emprendedor_id') int get emprendedorId; String? get nombre; String? get apellido; String? get email;@JsonKey(name: 'rol_en_emprendimiento') String? get rolEnEmprendimiento;
/// Create a copy of MemberDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MemberDtoCopyWith<MemberDto> get copyWith => _$MemberDtoCopyWithImpl<MemberDto>(this as MemberDto, _$identity);

  /// Serializes this MemberDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as MemberDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MemberDto&&(identical(other.emprendedorId, _this.emprendedorId) || other.emprendedorId == _this.emprendedorId)&&(identical(other.nombre, _this.nombre) || other.nombre == _this.nombre)&&(identical(other.apellido, _this.apellido) || other.apellido == _this.apellido)&&(identical(other.email, _this.email) || other.email == _this.email)&&(identical(other.rolEnEmprendimiento, _this.rolEnEmprendimiento) || other.rolEnEmprendimiento == _this.rolEnEmprendimiento));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as MemberDto;
  return Object.hash(runtimeType,_this.emprendedorId,_this.nombre,_this.apellido,_this.email,_this.rolEnEmprendimiento);
}

@override
String toString() {
  final _this = this as MemberDto;
  return 'MemberDto(emprendedorId: ${_this.emprendedorId}, nombre: ${_this.nombre}, apellido: ${_this.apellido}, email: ${_this.email}, rolEnEmprendimiento: ${_this.rolEnEmprendimiento})';
}


}

/// @nodoc
abstract mixin class $MemberDtoCopyWith<$Res>  {
  factory $MemberDtoCopyWith(MemberDto value, $Res Function(MemberDto) _then) = _$MemberDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'emprendedor_id') int emprendedorId, String? nombre, String? apellido, String? email,@JsonKey(name: 'rol_en_emprendimiento') String? rolEnEmprendimiento
});




}
/// @nodoc
class _$MemberDtoCopyWithImpl<$Res>
    implements $MemberDtoCopyWith<$Res> {
  _$MemberDtoCopyWithImpl(this._self, this._then);

  final MemberDto _self;
  final $Res Function(MemberDto) _then;

/// Create a copy of MemberDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? emprendedorId = null,Object? nombre = freezed,Object? apellido = freezed,Object? email = freezed,Object? rolEnEmprendimiento = freezed,}) {
  return _then(MemberDto(
emprendedorId: null == emprendedorId ? _self.emprendedorId : emprendedorId // ignore: cast_nullable_to_non_nullable
as int,nombre: freezed == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String?,apellido: freezed == apellido ? _self.apellido : apellido // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,rolEnEmprendimiento: freezed == rolEnEmprendimiento ? _self.rolEnEmprendimiento : rolEnEmprendimiento // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MemberDto].
extension MemberDtoPatterns on MemberDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MemberDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MemberDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MemberDto value)  $default,){
final _that = this;
switch (_that) {
case _MemberDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MemberDto value)?  $default,){
final _that = this;
switch (_that) {
case _MemberDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'emprendedor_id')  int emprendedorId,  String? nombre,  String? apellido,  String? email, @JsonKey(name: 'rol_en_emprendimiento')  String? rolEnEmprendimiento)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MemberDto() when $default != null:
return $default(_that.emprendedorId,_that.nombre,_that.apellido,_that.email,_that.rolEnEmprendimiento);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'emprendedor_id')  int emprendedorId,  String? nombre,  String? apellido,  String? email, @JsonKey(name: 'rol_en_emprendimiento')  String? rolEnEmprendimiento)  $default,) {final _that = this;
switch (_that) {
case _MemberDto():
return $default(_that.emprendedorId,_that.nombre,_that.apellido,_that.email,_that.rolEnEmprendimiento);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'emprendedor_id')  int emprendedorId,  String? nombre,  String? apellido,  String? email, @JsonKey(name: 'rol_en_emprendimiento')  String? rolEnEmprendimiento)?  $default,) {final _that = this;
switch (_that) {
case _MemberDto() when $default != null:
return $default(_that.emprendedorId,_that.nombre,_that.apellido,_that.email,_that.rolEnEmprendimiento);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MemberDto extends MemberDto {
  const _MemberDto({@JsonKey(name: 'emprendedor_id') required this.emprendedorId, this.nombre, this.apellido, this.email, @JsonKey(name: 'rol_en_emprendimiento') this.rolEnEmprendimiento}): super._();
  factory _MemberDto.fromJson(Map<String, dynamic> json) => _$MemberDtoFromJson(json);

@override@JsonKey(name: 'emprendedor_id') final  int emprendedorId;
@override final  String? nombre;
@override final  String? apellido;
@override final  String? email;
@override@JsonKey(name: 'rol_en_emprendimiento') final  String? rolEnEmprendimiento;

/// Create a copy of MemberDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MemberDtoCopyWith<_MemberDto> get copyWith => __$MemberDtoCopyWithImpl<_MemberDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MemberDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MemberDto&&(identical(other.emprendedorId, emprendedorId) || other.emprendedorId == emprendedorId)&&(identical(other.nombre, nombre) || other.nombre == nombre)&&(identical(other.apellido, apellido) || other.apellido == apellido)&&(identical(other.email, email) || other.email == email)&&(identical(other.rolEnEmprendimiento, rolEnEmprendimiento) || other.rolEnEmprendimiento == rolEnEmprendimiento));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,emprendedorId,nombre,apellido,email,rolEnEmprendimiento);
}

@override
String toString() {
    return 'MemberDto(emprendedorId: $emprendedorId, nombre: $nombre, apellido: $apellido, email: $email, rolEnEmprendimiento: $rolEnEmprendimiento)';
}


}

/// @nodoc
abstract mixin class _$MemberDtoCopyWith<$Res> implements $MemberDtoCopyWith<$Res> {
  factory _$MemberDtoCopyWith(_MemberDto value, $Res Function(_MemberDto) _then) = __$MemberDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'emprendedor_id') int emprendedorId, String? nombre, String? apellido, String? email,@JsonKey(name: 'rol_en_emprendimiento') String? rolEnEmprendimiento
});




}
/// @nodoc
class __$MemberDtoCopyWithImpl<$Res>
    implements _$MemberDtoCopyWith<$Res> {
  __$MemberDtoCopyWithImpl(this._self, this._then);

  final _MemberDto _self;
  final $Res Function(_MemberDto) _then;

/// Create a copy of MemberDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? emprendedorId = null,Object? nombre = freezed,Object? apellido = freezed,Object? email = freezed,Object? rolEnEmprendimiento = freezed,}) {
  return _then(_MemberDto(
emprendedorId: null == emprendedorId ? _self.emprendedorId : emprendedorId // ignore: cast_nullable_to_non_nullable
as int,nombre: freezed == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String?,apellido: freezed == apellido ? _self.apellido : apellido // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,rolEnEmprendimiento: freezed == rolEnEmprendimiento ? _self.rolEnEmprendimiento : rolEnEmprendimiento // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$VentureDto {

@JsonKey(name: 'emprendimiento_id') int get emprendimientoId; String get nombre;@JsonKey(name: 'etapa_actual') StageDto? get etapaActual; String? get descripcion; String? get sector; String? get estado; List<MemberDto> get integrantes;
/// Create a copy of VentureDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VentureDtoCopyWith<VentureDto> get copyWith => _$VentureDtoCopyWithImpl<VentureDto>(this as VentureDto, _$identity);

  /// Serializes this VentureDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as VentureDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VentureDto&&(identical(other.emprendimientoId, _this.emprendimientoId) || other.emprendimientoId == _this.emprendimientoId)&&(identical(other.nombre, _this.nombre) || other.nombre == _this.nombre)&&(identical(other.etapaActual, _this.etapaActual) || other.etapaActual == _this.etapaActual)&&(identical(other.descripcion, _this.descripcion) || other.descripcion == _this.descripcion)&&(identical(other.sector, _this.sector) || other.sector == _this.sector)&&(identical(other.estado, _this.estado) || other.estado == _this.estado)&&const DeepCollectionEquality().equals(other.integrantes, _this.integrantes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as VentureDto;
  return Object.hash(runtimeType,_this.emprendimientoId,_this.nombre,_this.etapaActual,_this.descripcion,_this.sector,_this.estado,const DeepCollectionEquality().hash(_this.integrantes));
}

@override
String toString() {
  final _this = this as VentureDto;
  return 'VentureDto(emprendimientoId: ${_this.emprendimientoId}, nombre: ${_this.nombre}, etapaActual: ${_this.etapaActual}, descripcion: ${_this.descripcion}, sector: ${_this.sector}, estado: ${_this.estado}, integrantes: ${_this.integrantes})';
}


}

/// @nodoc
abstract mixin class $VentureDtoCopyWith<$Res>  {
  factory $VentureDtoCopyWith(VentureDto value, $Res Function(VentureDto) _then) = _$VentureDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'emprendimiento_id') int emprendimientoId, String nombre,@JsonKey(name: 'etapa_actual') StageDto? etapaActual, String? descripcion, String? sector, String? estado, List<MemberDto> integrantes
});


$StageDtoCopyWith<$Res>? get etapaActual;

}
/// @nodoc
class _$VentureDtoCopyWithImpl<$Res>
    implements $VentureDtoCopyWith<$Res> {
  _$VentureDtoCopyWithImpl(this._self, this._then);

  final VentureDto _self;
  final $Res Function(VentureDto) _then;

/// Create a copy of VentureDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? emprendimientoId = null,Object? nombre = null,Object? etapaActual = freezed,Object? descripcion = freezed,Object? sector = freezed,Object? estado = freezed,Object? integrantes = null,}) {
  return _then(VentureDto(
emprendimientoId: null == emprendimientoId ? _self.emprendimientoId : emprendimientoId // ignore: cast_nullable_to_non_nullable
as int,nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,etapaActual: freezed == etapaActual ? _self.etapaActual : etapaActual // ignore: cast_nullable_to_non_nullable
as StageDto?,descripcion: freezed == descripcion ? _self.descripcion : descripcion // ignore: cast_nullable_to_non_nullable
as String?,sector: freezed == sector ? _self.sector : sector // ignore: cast_nullable_to_non_nullable
as String?,estado: freezed == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as String?,integrantes: null == integrantes ? _self.integrantes : integrantes // ignore: cast_nullable_to_non_nullable
as List<MemberDto>,
  ));
}
/// Create a copy of VentureDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StageDtoCopyWith<$Res>? get etapaActual {
    if (_self.etapaActual == null) {
    return null;
  }

  return $StageDtoCopyWith<$Res>(_self.etapaActual!, (value) {
    return _then(_self.copyWith(etapaActual: value));
  });
}
}


/// Adds pattern-matching-related methods to [VentureDto].
extension VentureDtoPatterns on VentureDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VentureDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VentureDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VentureDto value)  $default,){
final _that = this;
switch (_that) {
case _VentureDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VentureDto value)?  $default,){
final _that = this;
switch (_that) {
case _VentureDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'emprendimiento_id')  int emprendimientoId,  String nombre, @JsonKey(name: 'etapa_actual')  StageDto? etapaActual,  String? descripcion,  String? sector,  String? estado,  List<MemberDto> integrantes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VentureDto() when $default != null:
return $default(_that.emprendimientoId,_that.nombre,_that.etapaActual,_that.descripcion,_that.sector,_that.estado,_that.integrantes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'emprendimiento_id')  int emprendimientoId,  String nombre, @JsonKey(name: 'etapa_actual')  StageDto? etapaActual,  String? descripcion,  String? sector,  String? estado,  List<MemberDto> integrantes)  $default,) {final _that = this;
switch (_that) {
case _VentureDto():
return $default(_that.emprendimientoId,_that.nombre,_that.etapaActual,_that.descripcion,_that.sector,_that.estado,_that.integrantes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'emprendimiento_id')  int emprendimientoId,  String nombre, @JsonKey(name: 'etapa_actual')  StageDto? etapaActual,  String? descripcion,  String? sector,  String? estado,  List<MemberDto> integrantes)?  $default,) {final _that = this;
switch (_that) {
case _VentureDto() when $default != null:
return $default(_that.emprendimientoId,_that.nombre,_that.etapaActual,_that.descripcion,_that.sector,_that.estado,_that.integrantes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VentureDto extends VentureDto {
  const _VentureDto({@JsonKey(name: 'emprendimiento_id') required this.emprendimientoId, required this.nombre, @JsonKey(name: 'etapa_actual') this.etapaActual, this.descripcion, this.sector, this.estado,  List<MemberDto> integrantes = const <MemberDto>[]}): _integrantes = integrantes,super._();
  factory _VentureDto.fromJson(Map<String, dynamic> json) => _$VentureDtoFromJson(json);

@override@JsonKey(name: 'emprendimiento_id') final  int emprendimientoId;
@override final  String nombre;
@override@JsonKey(name: 'etapa_actual') final  StageDto? etapaActual;
@override final  String? descripcion;
@override final  String? sector;
@override final  String? estado;
 final  List<MemberDto> _integrantes;
@override@JsonKey() List<MemberDto> get integrantes {
  if (_integrantes is EqualUnmodifiableListView) return _integrantes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_integrantes);
}


/// Create a copy of VentureDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VentureDtoCopyWith<_VentureDto> get copyWith => __$VentureDtoCopyWithImpl<_VentureDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VentureDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _VentureDto&&(identical(other.emprendimientoId, emprendimientoId) || other.emprendimientoId == emprendimientoId)&&(identical(other.nombre, nombre) || other.nombre == nombre)&&(identical(other.etapaActual, etapaActual) || other.etapaActual == etapaActual)&&(identical(other.descripcion, descripcion) || other.descripcion == descripcion)&&(identical(other.sector, sector) || other.sector == sector)&&(identical(other.estado, estado) || other.estado == estado)&&const DeepCollectionEquality().equals(other.integrantes, _integrantes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,emprendimientoId,nombre,etapaActual,descripcion,sector,estado,const DeepCollectionEquality().hash(_integrantes));
}

@override
String toString() {
    return 'VentureDto(emprendimientoId: $emprendimientoId, nombre: $nombre, etapaActual: $etapaActual, descripcion: $descripcion, sector: $sector, estado: $estado, integrantes: $integrantes)';
}


}

/// @nodoc
abstract mixin class _$VentureDtoCopyWith<$Res> implements $VentureDtoCopyWith<$Res> {
  factory _$VentureDtoCopyWith(_VentureDto value, $Res Function(_VentureDto) _then) = __$VentureDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'emprendimiento_id') int emprendimientoId, String nombre,@JsonKey(name: 'etapa_actual') StageDto? etapaActual, String? descripcion, String? sector, String? estado, List<MemberDto> integrantes
});


@override $StageDtoCopyWith<$Res>? get etapaActual;

}
/// @nodoc
class __$VentureDtoCopyWithImpl<$Res>
    implements _$VentureDtoCopyWith<$Res> {
  __$VentureDtoCopyWithImpl(this._self, this._then);

  final _VentureDto _self;
  final $Res Function(_VentureDto) _then;

/// Create a copy of VentureDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? emprendimientoId = null,Object? nombre = null,Object? etapaActual = freezed,Object? descripcion = freezed,Object? sector = freezed,Object? estado = freezed,Object? integrantes = null,}) {
  return _then(_VentureDto(
emprendimientoId: null == emprendimientoId ? _self.emprendimientoId : emprendimientoId // ignore: cast_nullable_to_non_nullable
as int,nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,etapaActual: freezed == etapaActual ? _self.etapaActual : etapaActual // ignore: cast_nullable_to_non_nullable
as StageDto?,descripcion: freezed == descripcion ? _self.descripcion : descripcion // ignore: cast_nullable_to_non_nullable
as String?,sector: freezed == sector ? _self.sector : sector // ignore: cast_nullable_to_non_nullable
as String?,estado: freezed == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as String?,integrantes: null == integrantes ? _self._integrantes : integrantes // ignore: cast_nullable_to_non_nullable
as List<MemberDto>,
  ));
}

/// Create a copy of VentureDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StageDtoCopyWith<$Res>? get etapaActual {
    if (_self.etapaActual == null) {
    return null;
  }

  return $StageDtoCopyWith<$Res>(_self.etapaActual!, (value) {
    return _then(_self.copyWith(etapaActual: value));
  });
}
}

// dart format on
