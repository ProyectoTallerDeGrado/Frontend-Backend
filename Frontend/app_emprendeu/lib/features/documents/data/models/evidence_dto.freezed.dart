// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'evidence_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EvidenceDto {

@JsonKey(name: 'documento_id') int get documentoId; String get nombre; String? get tipo;@JsonKey(name: 'hito_id') int? get hitoId;
/// Create a copy of EvidenceDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EvidenceDtoCopyWith<EvidenceDto> get copyWith => _$EvidenceDtoCopyWithImpl<EvidenceDto>(this as EvidenceDto, _$identity);

  /// Serializes this EvidenceDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as EvidenceDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EvidenceDto&&(identical(other.documentoId, _this.documentoId) || other.documentoId == _this.documentoId)&&(identical(other.nombre, _this.nombre) || other.nombre == _this.nombre)&&(identical(other.tipo, _this.tipo) || other.tipo == _this.tipo)&&(identical(other.hitoId, _this.hitoId) || other.hitoId == _this.hitoId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as EvidenceDto;
  return Object.hash(runtimeType,_this.documentoId,_this.nombre,_this.tipo,_this.hitoId);
}

@override
String toString() {
  final _this = this as EvidenceDto;
  return 'EvidenceDto(documentoId: ${_this.documentoId}, nombre: ${_this.nombre}, tipo: ${_this.tipo}, hitoId: ${_this.hitoId})';
}


}

/// @nodoc
abstract mixin class $EvidenceDtoCopyWith<$Res>  {
  factory $EvidenceDtoCopyWith(EvidenceDto value, $Res Function(EvidenceDto) _then) = _$EvidenceDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'documento_id') int documentoId, String nombre, String? tipo,@JsonKey(name: 'hito_id') int? hitoId
});




}
/// @nodoc
class _$EvidenceDtoCopyWithImpl<$Res>
    implements $EvidenceDtoCopyWith<$Res> {
  _$EvidenceDtoCopyWithImpl(this._self, this._then);

  final EvidenceDto _self;
  final $Res Function(EvidenceDto) _then;

/// Create a copy of EvidenceDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? documentoId = null,Object? nombre = null,Object? tipo = freezed,Object? hitoId = freezed,}) {
  return _then(EvidenceDto(
documentoId: null == documentoId ? _self.documentoId : documentoId // ignore: cast_nullable_to_non_nullable
as int,nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,tipo: freezed == tipo ? _self.tipo : tipo // ignore: cast_nullable_to_non_nullable
as String?,hitoId: freezed == hitoId ? _self.hitoId : hitoId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [EvidenceDto].
extension EvidenceDtoPatterns on EvidenceDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EvidenceDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EvidenceDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EvidenceDto value)  $default,){
final _that = this;
switch (_that) {
case _EvidenceDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EvidenceDto value)?  $default,){
final _that = this;
switch (_that) {
case _EvidenceDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'documento_id')  int documentoId,  String nombre,  String? tipo, @JsonKey(name: 'hito_id')  int? hitoId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EvidenceDto() when $default != null:
return $default(_that.documentoId,_that.nombre,_that.tipo,_that.hitoId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'documento_id')  int documentoId,  String nombre,  String? tipo, @JsonKey(name: 'hito_id')  int? hitoId)  $default,) {final _that = this;
switch (_that) {
case _EvidenceDto():
return $default(_that.documentoId,_that.nombre,_that.tipo,_that.hitoId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'documento_id')  int documentoId,  String nombre,  String? tipo, @JsonKey(name: 'hito_id')  int? hitoId)?  $default,) {final _that = this;
switch (_that) {
case _EvidenceDto() when $default != null:
return $default(_that.documentoId,_that.nombre,_that.tipo,_that.hitoId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EvidenceDto extends EvidenceDto {
  const _EvidenceDto({@JsonKey(name: 'documento_id') required this.documentoId, required this.nombre, this.tipo, @JsonKey(name: 'hito_id') this.hitoId}): super._();
  factory _EvidenceDto.fromJson(Map<String, dynamic> json) => _$EvidenceDtoFromJson(json);

@override@JsonKey(name: 'documento_id') final  int documentoId;
@override final  String nombre;
@override final  String? tipo;
@override@JsonKey(name: 'hito_id') final  int? hitoId;

/// Create a copy of EvidenceDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EvidenceDtoCopyWith<_EvidenceDto> get copyWith => __$EvidenceDtoCopyWithImpl<_EvidenceDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EvidenceDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EvidenceDto&&(identical(other.documentoId, documentoId) || other.documentoId == documentoId)&&(identical(other.nombre, nombre) || other.nombre == nombre)&&(identical(other.tipo, tipo) || other.tipo == tipo)&&(identical(other.hitoId, hitoId) || other.hitoId == hitoId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,documentoId,nombre,tipo,hitoId);
}

@override
String toString() {
    return 'EvidenceDto(documentoId: $documentoId, nombre: $nombre, tipo: $tipo, hitoId: $hitoId)';
}


}

/// @nodoc
abstract mixin class _$EvidenceDtoCopyWith<$Res> implements $EvidenceDtoCopyWith<$Res> {
  factory _$EvidenceDtoCopyWith(_EvidenceDto value, $Res Function(_EvidenceDto) _then) = __$EvidenceDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'documento_id') int documentoId, String nombre, String? tipo,@JsonKey(name: 'hito_id') int? hitoId
});




}
/// @nodoc
class __$EvidenceDtoCopyWithImpl<$Res>
    implements _$EvidenceDtoCopyWith<$Res> {
  __$EvidenceDtoCopyWithImpl(this._self, this._then);

  final _EvidenceDto _self;
  final $Res Function(_EvidenceDto) _then;

/// Create a copy of EvidenceDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? documentoId = null,Object? nombre = null,Object? tipo = freezed,Object? hitoId = freezed,}) {
  return _then(_EvidenceDto(
documentoId: null == documentoId ? _self.documentoId : documentoId // ignore: cast_nullable_to_non_nullable
as int,nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,tipo: freezed == tipo ? _self.tipo : tipo // ignore: cast_nullable_to_non_nullable
as String?,hitoId: freezed == hitoId ? _self.hitoId : hitoId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
