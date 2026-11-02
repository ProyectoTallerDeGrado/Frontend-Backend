// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'history_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HistoryEventDto {

 String get tipo;@JsonKey(name: 'referencia_id') int get referenciaId; DateTime? get fecha; String get titulo; String? get detalle; String? get estado; String? get autor;
/// Create a copy of HistoryEventDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HistoryEventDtoCopyWith<HistoryEventDto> get copyWith => _$HistoryEventDtoCopyWithImpl<HistoryEventDto>(this as HistoryEventDto, _$identity);

  /// Serializes this HistoryEventDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as HistoryEventDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HistoryEventDto&&(identical(other.tipo, _this.tipo) || other.tipo == _this.tipo)&&(identical(other.referenciaId, _this.referenciaId) || other.referenciaId == _this.referenciaId)&&(identical(other.fecha, _this.fecha) || other.fecha == _this.fecha)&&(identical(other.titulo, _this.titulo) || other.titulo == _this.titulo)&&(identical(other.detalle, _this.detalle) || other.detalle == _this.detalle)&&(identical(other.estado, _this.estado) || other.estado == _this.estado)&&(identical(other.autor, _this.autor) || other.autor == _this.autor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as HistoryEventDto;
  return Object.hash(runtimeType,_this.tipo,_this.referenciaId,_this.fecha,_this.titulo,_this.detalle,_this.estado,_this.autor);
}

@override
String toString() {
  final _this = this as HistoryEventDto;
  return 'HistoryEventDto(tipo: ${_this.tipo}, referenciaId: ${_this.referenciaId}, fecha: ${_this.fecha}, titulo: ${_this.titulo}, detalle: ${_this.detalle}, estado: ${_this.estado}, autor: ${_this.autor})';
}


}

/// @nodoc
abstract mixin class $HistoryEventDtoCopyWith<$Res>  {
  factory $HistoryEventDtoCopyWith(HistoryEventDto value, $Res Function(HistoryEventDto) _then) = _$HistoryEventDtoCopyWithImpl;
@useResult
$Res call({
 String tipo,@JsonKey(name: 'referencia_id') int referenciaId, DateTime? fecha, String titulo, String? detalle, String? estado, String? autor
});




}
/// @nodoc
class _$HistoryEventDtoCopyWithImpl<$Res>
    implements $HistoryEventDtoCopyWith<$Res> {
  _$HistoryEventDtoCopyWithImpl(this._self, this._then);

  final HistoryEventDto _self;
  final $Res Function(HistoryEventDto) _then;

/// Create a copy of HistoryEventDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tipo = null,Object? referenciaId = null,Object? fecha = freezed,Object? titulo = null,Object? detalle = freezed,Object? estado = freezed,Object? autor = freezed,}) {
  return _then(HistoryEventDto(
tipo: null == tipo ? _self.tipo : tipo // ignore: cast_nullable_to_non_nullable
as String,referenciaId: null == referenciaId ? _self.referenciaId : referenciaId // ignore: cast_nullable_to_non_nullable
as int,fecha: freezed == fecha ? _self.fecha : fecha // ignore: cast_nullable_to_non_nullable
as DateTime?,titulo: null == titulo ? _self.titulo : titulo // ignore: cast_nullable_to_non_nullable
as String,detalle: freezed == detalle ? _self.detalle : detalle // ignore: cast_nullable_to_non_nullable
as String?,estado: freezed == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as String?,autor: freezed == autor ? _self.autor : autor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [HistoryEventDto].
extension HistoryEventDtoPatterns on HistoryEventDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HistoryEventDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HistoryEventDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HistoryEventDto value)  $default,){
final _that = this;
switch (_that) {
case _HistoryEventDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HistoryEventDto value)?  $default,){
final _that = this;
switch (_that) {
case _HistoryEventDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String tipo, @JsonKey(name: 'referencia_id')  int referenciaId,  DateTime? fecha,  String titulo,  String? detalle,  String? estado,  String? autor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HistoryEventDto() when $default != null:
return $default(_that.tipo,_that.referenciaId,_that.fecha,_that.titulo,_that.detalle,_that.estado,_that.autor);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String tipo, @JsonKey(name: 'referencia_id')  int referenciaId,  DateTime? fecha,  String titulo,  String? detalle,  String? estado,  String? autor)  $default,) {final _that = this;
switch (_that) {
case _HistoryEventDto():
return $default(_that.tipo,_that.referenciaId,_that.fecha,_that.titulo,_that.detalle,_that.estado,_that.autor);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String tipo, @JsonKey(name: 'referencia_id')  int referenciaId,  DateTime? fecha,  String titulo,  String? detalle,  String? estado,  String? autor)?  $default,) {final _that = this;
switch (_that) {
case _HistoryEventDto() when $default != null:
return $default(_that.tipo,_that.referenciaId,_that.fecha,_that.titulo,_that.detalle,_that.estado,_that.autor);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HistoryEventDto extends HistoryEventDto {
  const _HistoryEventDto({required this.tipo, @JsonKey(name: 'referencia_id') required this.referenciaId, this.fecha, required this.titulo, this.detalle, this.estado, this.autor}): super._();
  factory _HistoryEventDto.fromJson(Map<String, dynamic> json) => _$HistoryEventDtoFromJson(json);

@override final  String tipo;
@override@JsonKey(name: 'referencia_id') final  int referenciaId;
@override final  DateTime? fecha;
@override final  String titulo;
@override final  String? detalle;
@override final  String? estado;
@override final  String? autor;

/// Create a copy of HistoryEventDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HistoryEventDtoCopyWith<_HistoryEventDto> get copyWith => __$HistoryEventDtoCopyWithImpl<_HistoryEventDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HistoryEventDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _HistoryEventDto&&(identical(other.tipo, tipo) || other.tipo == tipo)&&(identical(other.referenciaId, referenciaId) || other.referenciaId == referenciaId)&&(identical(other.fecha, fecha) || other.fecha == fecha)&&(identical(other.titulo, titulo) || other.titulo == titulo)&&(identical(other.detalle, detalle) || other.detalle == detalle)&&(identical(other.estado, estado) || other.estado == estado)&&(identical(other.autor, autor) || other.autor == autor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,tipo,referenciaId,fecha,titulo,detalle,estado,autor);
}

@override
String toString() {
    return 'HistoryEventDto(tipo: $tipo, referenciaId: $referenciaId, fecha: $fecha, titulo: $titulo, detalle: $detalle, estado: $estado, autor: $autor)';
}


}

/// @nodoc
abstract mixin class _$HistoryEventDtoCopyWith<$Res> implements $HistoryEventDtoCopyWith<$Res> {
  factory _$HistoryEventDtoCopyWith(_HistoryEventDto value, $Res Function(_HistoryEventDto) _then) = __$HistoryEventDtoCopyWithImpl;
@override @useResult
$Res call({
 String tipo,@JsonKey(name: 'referencia_id') int referenciaId, DateTime? fecha, String titulo, String? detalle, String? estado, String? autor
});




}
/// @nodoc
class __$HistoryEventDtoCopyWithImpl<$Res>
    implements _$HistoryEventDtoCopyWith<$Res> {
  __$HistoryEventDtoCopyWithImpl(this._self, this._then);

  final _HistoryEventDto _self;
  final $Res Function(_HistoryEventDto) _then;

/// Create a copy of HistoryEventDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tipo = null,Object? referenciaId = null,Object? fecha = freezed,Object? titulo = null,Object? detalle = freezed,Object? estado = freezed,Object? autor = freezed,}) {
  return _then(_HistoryEventDto(
tipo: null == tipo ? _self.tipo : tipo // ignore: cast_nullable_to_non_nullable
as String,referenciaId: null == referenciaId ? _self.referenciaId : referenciaId // ignore: cast_nullable_to_non_nullable
as int,fecha: freezed == fecha ? _self.fecha : fecha // ignore: cast_nullable_to_non_nullable
as DateTime?,titulo: null == titulo ? _self.titulo : titulo // ignore: cast_nullable_to_non_nullable
as String,detalle: freezed == detalle ? _self.detalle : detalle // ignore: cast_nullable_to_non_nullable
as String?,estado: freezed == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as String?,autor: freezed == autor ? _self.autor : autor // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
