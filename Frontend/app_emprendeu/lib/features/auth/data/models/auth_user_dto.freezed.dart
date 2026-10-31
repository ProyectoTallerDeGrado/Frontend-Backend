// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_user_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AuthUserDto {

@JsonKey(name: 'usuario_id') int get usuarioId; String get nombre; String get apellido; String get email; String? get rol; List<String> get permisos;
/// Create a copy of AuthUserDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthUserDtoCopyWith<AuthUserDto> get copyWith => _$AuthUserDtoCopyWithImpl<AuthUserDto>(this as AuthUserDto, _$identity);

  /// Serializes this AuthUserDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as AuthUserDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthUserDto&&(identical(other.usuarioId, _this.usuarioId) || other.usuarioId == _this.usuarioId)&&(identical(other.nombre, _this.nombre) || other.nombre == _this.nombre)&&(identical(other.apellido, _this.apellido) || other.apellido == _this.apellido)&&(identical(other.email, _this.email) || other.email == _this.email)&&(identical(other.rol, _this.rol) || other.rol == _this.rol)&&const DeepCollectionEquality().equals(other.permisos, _this.permisos));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AuthUserDto;
  return Object.hash(runtimeType,_this.usuarioId,_this.nombre,_this.apellido,_this.email,_this.rol,const DeepCollectionEquality().hash(_this.permisos));
}

@override
String toString() {
  final _this = this as AuthUserDto;
  return 'AuthUserDto(usuarioId: ${_this.usuarioId}, nombre: ${_this.nombre}, apellido: ${_this.apellido}, email: ${_this.email}, rol: ${_this.rol}, permisos: ${_this.permisos})';
}


}

/// @nodoc
abstract mixin class $AuthUserDtoCopyWith<$Res>  {
  factory $AuthUserDtoCopyWith(AuthUserDto value, $Res Function(AuthUserDto) _then) = _$AuthUserDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'usuario_id') int usuarioId, String nombre, String apellido, String email, String? rol, List<String> permisos
});




}
/// @nodoc
class _$AuthUserDtoCopyWithImpl<$Res>
    implements $AuthUserDtoCopyWith<$Res> {
  _$AuthUserDtoCopyWithImpl(this._self, this._then);

  final AuthUserDto _self;
  final $Res Function(AuthUserDto) _then;

/// Create a copy of AuthUserDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? usuarioId = null,Object? nombre = null,Object? apellido = null,Object? email = null,Object? rol = freezed,Object? permisos = null,}) {
  return _then(AuthUserDto(
usuarioId: null == usuarioId ? _self.usuarioId : usuarioId // ignore: cast_nullable_to_non_nullable
as int,nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,apellido: null == apellido ? _self.apellido : apellido // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,rol: freezed == rol ? _self.rol : rol // ignore: cast_nullable_to_non_nullable
as String?,permisos: null == permisos ? _self.permisos : permisos // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [AuthUserDto].
extension AuthUserDtoPatterns on AuthUserDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthUserDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthUserDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthUserDto value)  $default,){
final _that = this;
switch (_that) {
case _AuthUserDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthUserDto value)?  $default,){
final _that = this;
switch (_that) {
case _AuthUserDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'usuario_id')  int usuarioId,  String nombre,  String apellido,  String email,  String? rol,  List<String> permisos)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthUserDto() when $default != null:
return $default(_that.usuarioId,_that.nombre,_that.apellido,_that.email,_that.rol,_that.permisos);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'usuario_id')  int usuarioId,  String nombre,  String apellido,  String email,  String? rol,  List<String> permisos)  $default,) {final _that = this;
switch (_that) {
case _AuthUserDto():
return $default(_that.usuarioId,_that.nombre,_that.apellido,_that.email,_that.rol,_that.permisos);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'usuario_id')  int usuarioId,  String nombre,  String apellido,  String email,  String? rol,  List<String> permisos)?  $default,) {final _that = this;
switch (_that) {
case _AuthUserDto() when $default != null:
return $default(_that.usuarioId,_that.nombre,_that.apellido,_that.email,_that.rol,_that.permisos);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AuthUserDto extends AuthUserDto {
  const _AuthUserDto({@JsonKey(name: 'usuario_id') required this.usuarioId, required this.nombre, required this.apellido, required this.email, this.rol,  List<String> permisos = const <String>[]}): _permisos = permisos,super._();
  factory _AuthUserDto.fromJson(Map<String, dynamic> json) => _$AuthUserDtoFromJson(json);

@override@JsonKey(name: 'usuario_id') final  int usuarioId;
@override final  String nombre;
@override final  String apellido;
@override final  String email;
@override final  String? rol;
 final  List<String> _permisos;
@override@JsonKey() List<String> get permisos {
  if (_permisos is EqualUnmodifiableListView) return _permisos;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_permisos);
}


/// Create a copy of AuthUserDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthUserDtoCopyWith<_AuthUserDto> get copyWith => __$AuthUserDtoCopyWithImpl<_AuthUserDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AuthUserDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthUserDto&&(identical(other.usuarioId, usuarioId) || other.usuarioId == usuarioId)&&(identical(other.nombre, nombre) || other.nombre == nombre)&&(identical(other.apellido, apellido) || other.apellido == apellido)&&(identical(other.email, email) || other.email == email)&&(identical(other.rol, rol) || other.rol == rol)&&const DeepCollectionEquality().equals(other.permisos, _permisos));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,usuarioId,nombre,apellido,email,rol,const DeepCollectionEquality().hash(_permisos));
}

@override
String toString() {
    return 'AuthUserDto(usuarioId: $usuarioId, nombre: $nombre, apellido: $apellido, email: $email, rol: $rol, permisos: $permisos)';
}


}

/// @nodoc
abstract mixin class _$AuthUserDtoCopyWith<$Res> implements $AuthUserDtoCopyWith<$Res> {
  factory _$AuthUserDtoCopyWith(_AuthUserDto value, $Res Function(_AuthUserDto) _then) = __$AuthUserDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'usuario_id') int usuarioId, String nombre, String apellido, String email, String? rol, List<String> permisos
});




}
/// @nodoc
class __$AuthUserDtoCopyWithImpl<$Res>
    implements _$AuthUserDtoCopyWith<$Res> {
  __$AuthUserDtoCopyWithImpl(this._self, this._then);

  final _AuthUserDto _self;
  final $Res Function(_AuthUserDto) _then;

/// Create a copy of AuthUserDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? usuarioId = null,Object? nombre = null,Object? apellido = null,Object? email = null,Object? rol = freezed,Object? permisos = null,}) {
  return _then(_AuthUserDto(
usuarioId: null == usuarioId ? _self.usuarioId : usuarioId // ignore: cast_nullable_to_non_nullable
as int,nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,apellido: null == apellido ? _self.apellido : apellido // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,rol: freezed == rol ? _self.rol : rol // ignore: cast_nullable_to_non_nullable
as String?,permisos: null == permisos ? _self._permisos : permisos // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
