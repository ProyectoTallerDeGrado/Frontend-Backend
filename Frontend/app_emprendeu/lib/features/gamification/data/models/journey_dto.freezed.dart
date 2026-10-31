// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'journey_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$JourneyStageDto {

@JsonKey(name: 'etapa_id') int get etapaId; String get nombre; String get estado;
/// Create a copy of JourneyStageDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JourneyStageDtoCopyWith<JourneyStageDto> get copyWith => _$JourneyStageDtoCopyWithImpl<JourneyStageDto>(this as JourneyStageDto, _$identity);

  /// Serializes this JourneyStageDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as JourneyStageDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JourneyStageDto&&(identical(other.etapaId, _this.etapaId) || other.etapaId == _this.etapaId)&&(identical(other.nombre, _this.nombre) || other.nombre == _this.nombre)&&(identical(other.estado, _this.estado) || other.estado == _this.estado));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as JourneyStageDto;
  return Object.hash(runtimeType,_this.etapaId,_this.nombre,_this.estado);
}

@override
String toString() {
  final _this = this as JourneyStageDto;
  return 'JourneyStageDto(etapaId: ${_this.etapaId}, nombre: ${_this.nombre}, estado: ${_this.estado})';
}


}

/// @nodoc
abstract mixin class $JourneyStageDtoCopyWith<$Res>  {
  factory $JourneyStageDtoCopyWith(JourneyStageDto value, $Res Function(JourneyStageDto) _then) = _$JourneyStageDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'etapa_id') int etapaId, String nombre, String estado
});




}
/// @nodoc
class _$JourneyStageDtoCopyWithImpl<$Res>
    implements $JourneyStageDtoCopyWith<$Res> {
  _$JourneyStageDtoCopyWithImpl(this._self, this._then);

  final JourneyStageDto _self;
  final $Res Function(JourneyStageDto) _then;

/// Create a copy of JourneyStageDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? etapaId = null,Object? nombre = null,Object? estado = null,}) {
  return _then(JourneyStageDto(
etapaId: null == etapaId ? _self.etapaId : etapaId // ignore: cast_nullable_to_non_nullable
as int,nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,estado: null == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [JourneyStageDto].
extension JourneyStageDtoPatterns on JourneyStageDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JourneyStageDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JourneyStageDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JourneyStageDto value)  $default,){
final _that = this;
switch (_that) {
case _JourneyStageDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JourneyStageDto value)?  $default,){
final _that = this;
switch (_that) {
case _JourneyStageDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'etapa_id')  int etapaId,  String nombre,  String estado)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JourneyStageDto() when $default != null:
return $default(_that.etapaId,_that.nombre,_that.estado);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'etapa_id')  int etapaId,  String nombre,  String estado)  $default,) {final _that = this;
switch (_that) {
case _JourneyStageDto():
return $default(_that.etapaId,_that.nombre,_that.estado);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'etapa_id')  int etapaId,  String nombre,  String estado)?  $default,) {final _that = this;
switch (_that) {
case _JourneyStageDto() when $default != null:
return $default(_that.etapaId,_that.nombre,_that.estado);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _JourneyStageDto implements JourneyStageDto {
  const _JourneyStageDto({@JsonKey(name: 'etapa_id') required this.etapaId, required this.nombre, required this.estado});
  factory _JourneyStageDto.fromJson(Map<String, dynamic> json) => _$JourneyStageDtoFromJson(json);

@override@JsonKey(name: 'etapa_id') final  int etapaId;
@override final  String nombre;
@override final  String estado;

/// Create a copy of JourneyStageDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JourneyStageDtoCopyWith<_JourneyStageDto> get copyWith => __$JourneyStageDtoCopyWithImpl<_JourneyStageDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$JourneyStageDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _JourneyStageDto&&(identical(other.etapaId, etapaId) || other.etapaId == etapaId)&&(identical(other.nombre, nombre) || other.nombre == nombre)&&(identical(other.estado, estado) || other.estado == estado));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,etapaId,nombre,estado);
}

@override
String toString() {
    return 'JourneyStageDto(etapaId: $etapaId, nombre: $nombre, estado: $estado)';
}


}

/// @nodoc
abstract mixin class _$JourneyStageDtoCopyWith<$Res> implements $JourneyStageDtoCopyWith<$Res> {
  factory _$JourneyStageDtoCopyWith(_JourneyStageDto value, $Res Function(_JourneyStageDto) _then) = __$JourneyStageDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'etapa_id') int etapaId, String nombre, String estado
});




}
/// @nodoc
class __$JourneyStageDtoCopyWithImpl<$Res>
    implements _$JourneyStageDtoCopyWith<$Res> {
  __$JourneyStageDtoCopyWithImpl(this._self, this._then);

  final _JourneyStageDto _self;
  final $Res Function(_JourneyStageDto) _then;

/// Create a copy of JourneyStageDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? etapaId = null,Object? nombre = null,Object? estado = null,}) {
  return _then(_JourneyStageDto(
etapaId: null == etapaId ? _self.etapaId : etapaId // ignore: cast_nullable_to_non_nullable
as int,nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,estado: null == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$JourneyChallengeDto {

@JsonKey(name: 'reto_id') int get retoId; String get titulo; String? get descripcion; String? get etapa;@JsonKey(name: 'xp_recompensa') int get xpRecompensa; String get estado;@JsonKey(name: 'fecha_completado') DateTime? get fechaCompletado;
/// Create a copy of JourneyChallengeDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JourneyChallengeDtoCopyWith<JourneyChallengeDto> get copyWith => _$JourneyChallengeDtoCopyWithImpl<JourneyChallengeDto>(this as JourneyChallengeDto, _$identity);

  /// Serializes this JourneyChallengeDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as JourneyChallengeDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JourneyChallengeDto&&(identical(other.retoId, _this.retoId) || other.retoId == _this.retoId)&&(identical(other.titulo, _this.titulo) || other.titulo == _this.titulo)&&(identical(other.descripcion, _this.descripcion) || other.descripcion == _this.descripcion)&&(identical(other.etapa, _this.etapa) || other.etapa == _this.etapa)&&(identical(other.xpRecompensa, _this.xpRecompensa) || other.xpRecompensa == _this.xpRecompensa)&&(identical(other.estado, _this.estado) || other.estado == _this.estado)&&(identical(other.fechaCompletado, _this.fechaCompletado) || other.fechaCompletado == _this.fechaCompletado));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as JourneyChallengeDto;
  return Object.hash(runtimeType,_this.retoId,_this.titulo,_this.descripcion,_this.etapa,_this.xpRecompensa,_this.estado,_this.fechaCompletado);
}

@override
String toString() {
  final _this = this as JourneyChallengeDto;
  return 'JourneyChallengeDto(retoId: ${_this.retoId}, titulo: ${_this.titulo}, descripcion: ${_this.descripcion}, etapa: ${_this.etapa}, xpRecompensa: ${_this.xpRecompensa}, estado: ${_this.estado}, fechaCompletado: ${_this.fechaCompletado})';
}


}

/// @nodoc
abstract mixin class $JourneyChallengeDtoCopyWith<$Res>  {
  factory $JourneyChallengeDtoCopyWith(JourneyChallengeDto value, $Res Function(JourneyChallengeDto) _then) = _$JourneyChallengeDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'reto_id') int retoId, String titulo, String? descripcion, String? etapa,@JsonKey(name: 'xp_recompensa') int xpRecompensa, String estado,@JsonKey(name: 'fecha_completado') DateTime? fechaCompletado
});




}
/// @nodoc
class _$JourneyChallengeDtoCopyWithImpl<$Res>
    implements $JourneyChallengeDtoCopyWith<$Res> {
  _$JourneyChallengeDtoCopyWithImpl(this._self, this._then);

  final JourneyChallengeDto _self;
  final $Res Function(JourneyChallengeDto) _then;

/// Create a copy of JourneyChallengeDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? retoId = null,Object? titulo = null,Object? descripcion = freezed,Object? etapa = freezed,Object? xpRecompensa = null,Object? estado = null,Object? fechaCompletado = freezed,}) {
  return _then(JourneyChallengeDto(
retoId: null == retoId ? _self.retoId : retoId // ignore: cast_nullable_to_non_nullable
as int,titulo: null == titulo ? _self.titulo : titulo // ignore: cast_nullable_to_non_nullable
as String,descripcion: freezed == descripcion ? _self.descripcion : descripcion // ignore: cast_nullable_to_non_nullable
as String?,etapa: freezed == etapa ? _self.etapa : etapa // ignore: cast_nullable_to_non_nullable
as String?,xpRecompensa: null == xpRecompensa ? _self.xpRecompensa : xpRecompensa // ignore: cast_nullable_to_non_nullable
as int,estado: null == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as String,fechaCompletado: freezed == fechaCompletado ? _self.fechaCompletado : fechaCompletado // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [JourneyChallengeDto].
extension JourneyChallengeDtoPatterns on JourneyChallengeDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JourneyChallengeDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JourneyChallengeDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JourneyChallengeDto value)  $default,){
final _that = this;
switch (_that) {
case _JourneyChallengeDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JourneyChallengeDto value)?  $default,){
final _that = this;
switch (_that) {
case _JourneyChallengeDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'reto_id')  int retoId,  String titulo,  String? descripcion,  String? etapa, @JsonKey(name: 'xp_recompensa')  int xpRecompensa,  String estado, @JsonKey(name: 'fecha_completado')  DateTime? fechaCompletado)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JourneyChallengeDto() when $default != null:
return $default(_that.retoId,_that.titulo,_that.descripcion,_that.etapa,_that.xpRecompensa,_that.estado,_that.fechaCompletado);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'reto_id')  int retoId,  String titulo,  String? descripcion,  String? etapa, @JsonKey(name: 'xp_recompensa')  int xpRecompensa,  String estado, @JsonKey(name: 'fecha_completado')  DateTime? fechaCompletado)  $default,) {final _that = this;
switch (_that) {
case _JourneyChallengeDto():
return $default(_that.retoId,_that.titulo,_that.descripcion,_that.etapa,_that.xpRecompensa,_that.estado,_that.fechaCompletado);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'reto_id')  int retoId,  String titulo,  String? descripcion,  String? etapa, @JsonKey(name: 'xp_recompensa')  int xpRecompensa,  String estado, @JsonKey(name: 'fecha_completado')  DateTime? fechaCompletado)?  $default,) {final _that = this;
switch (_that) {
case _JourneyChallengeDto() when $default != null:
return $default(_that.retoId,_that.titulo,_that.descripcion,_that.etapa,_that.xpRecompensa,_that.estado,_that.fechaCompletado);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _JourneyChallengeDto implements JourneyChallengeDto {
  const _JourneyChallengeDto({@JsonKey(name: 'reto_id') required this.retoId, required this.titulo, this.descripcion, this.etapa, @JsonKey(name: 'xp_recompensa') required this.xpRecompensa, required this.estado, @JsonKey(name: 'fecha_completado') this.fechaCompletado});
  factory _JourneyChallengeDto.fromJson(Map<String, dynamic> json) => _$JourneyChallengeDtoFromJson(json);

@override@JsonKey(name: 'reto_id') final  int retoId;
@override final  String titulo;
@override final  String? descripcion;
@override final  String? etapa;
@override@JsonKey(name: 'xp_recompensa') final  int xpRecompensa;
@override final  String estado;
@override@JsonKey(name: 'fecha_completado') final  DateTime? fechaCompletado;

/// Create a copy of JourneyChallengeDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JourneyChallengeDtoCopyWith<_JourneyChallengeDto> get copyWith => __$JourneyChallengeDtoCopyWithImpl<_JourneyChallengeDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$JourneyChallengeDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _JourneyChallengeDto&&(identical(other.retoId, retoId) || other.retoId == retoId)&&(identical(other.titulo, titulo) || other.titulo == titulo)&&(identical(other.descripcion, descripcion) || other.descripcion == descripcion)&&(identical(other.etapa, etapa) || other.etapa == etapa)&&(identical(other.xpRecompensa, xpRecompensa) || other.xpRecompensa == xpRecompensa)&&(identical(other.estado, estado) || other.estado == estado)&&(identical(other.fechaCompletado, fechaCompletado) || other.fechaCompletado == fechaCompletado));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,retoId,titulo,descripcion,etapa,xpRecompensa,estado,fechaCompletado);
}

@override
String toString() {
    return 'JourneyChallengeDto(retoId: $retoId, titulo: $titulo, descripcion: $descripcion, etapa: $etapa, xpRecompensa: $xpRecompensa, estado: $estado, fechaCompletado: $fechaCompletado)';
}


}

/// @nodoc
abstract mixin class _$JourneyChallengeDtoCopyWith<$Res> implements $JourneyChallengeDtoCopyWith<$Res> {
  factory _$JourneyChallengeDtoCopyWith(_JourneyChallengeDto value, $Res Function(_JourneyChallengeDto) _then) = __$JourneyChallengeDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'reto_id') int retoId, String titulo, String? descripcion, String? etapa,@JsonKey(name: 'xp_recompensa') int xpRecompensa, String estado,@JsonKey(name: 'fecha_completado') DateTime? fechaCompletado
});




}
/// @nodoc
class __$JourneyChallengeDtoCopyWithImpl<$Res>
    implements _$JourneyChallengeDtoCopyWith<$Res> {
  __$JourneyChallengeDtoCopyWithImpl(this._self, this._then);

  final _JourneyChallengeDto _self;
  final $Res Function(_JourneyChallengeDto) _then;

/// Create a copy of JourneyChallengeDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? retoId = null,Object? titulo = null,Object? descripcion = freezed,Object? etapa = freezed,Object? xpRecompensa = null,Object? estado = null,Object? fechaCompletado = freezed,}) {
  return _then(_JourneyChallengeDto(
retoId: null == retoId ? _self.retoId : retoId // ignore: cast_nullable_to_non_nullable
as int,titulo: null == titulo ? _self.titulo : titulo // ignore: cast_nullable_to_non_nullable
as String,descripcion: freezed == descripcion ? _self.descripcion : descripcion // ignore: cast_nullable_to_non_nullable
as String?,etapa: freezed == etapa ? _self.etapa : etapa // ignore: cast_nullable_to_non_nullable
as String?,xpRecompensa: null == xpRecompensa ? _self.xpRecompensa : xpRecompensa // ignore: cast_nullable_to_non_nullable
as int,estado: null == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as String,fechaCompletado: freezed == fechaCompletado ? _self.fechaCompletado : fechaCompletado // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$JourneyDto {

@JsonKey(name: 'emprendimiento_id') int get emprendimientoId;@JsonKey(name: 'xp_total') int get xpTotal; int get nivel; List<JourneyStageDto> get etapas; List<JourneyChallengeDto> get retos;
/// Create a copy of JourneyDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JourneyDtoCopyWith<JourneyDto> get copyWith => _$JourneyDtoCopyWithImpl<JourneyDto>(this as JourneyDto, _$identity);

  /// Serializes this JourneyDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as JourneyDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JourneyDto&&(identical(other.emprendimientoId, _this.emprendimientoId) || other.emprendimientoId == _this.emprendimientoId)&&(identical(other.xpTotal, _this.xpTotal) || other.xpTotal == _this.xpTotal)&&(identical(other.nivel, _this.nivel) || other.nivel == _this.nivel)&&const DeepCollectionEquality().equals(other.etapas, _this.etapas)&&const DeepCollectionEquality().equals(other.retos, _this.retos));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as JourneyDto;
  return Object.hash(runtimeType,_this.emprendimientoId,_this.xpTotal,_this.nivel,const DeepCollectionEquality().hash(_this.etapas),const DeepCollectionEquality().hash(_this.retos));
}

@override
String toString() {
  final _this = this as JourneyDto;
  return 'JourneyDto(emprendimientoId: ${_this.emprendimientoId}, xpTotal: ${_this.xpTotal}, nivel: ${_this.nivel}, etapas: ${_this.etapas}, retos: ${_this.retos})';
}


}

/// @nodoc
abstract mixin class $JourneyDtoCopyWith<$Res>  {
  factory $JourneyDtoCopyWith(JourneyDto value, $Res Function(JourneyDto) _then) = _$JourneyDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'emprendimiento_id') int emprendimientoId,@JsonKey(name: 'xp_total') int xpTotal, int nivel, List<JourneyStageDto> etapas, List<JourneyChallengeDto> retos
});




}
/// @nodoc
class _$JourneyDtoCopyWithImpl<$Res>
    implements $JourneyDtoCopyWith<$Res> {
  _$JourneyDtoCopyWithImpl(this._self, this._then);

  final JourneyDto _self;
  final $Res Function(JourneyDto) _then;

/// Create a copy of JourneyDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? emprendimientoId = null,Object? xpTotal = null,Object? nivel = null,Object? etapas = null,Object? retos = null,}) {
  return _then(JourneyDto(
emprendimientoId: null == emprendimientoId ? _self.emprendimientoId : emprendimientoId // ignore: cast_nullable_to_non_nullable
as int,xpTotal: null == xpTotal ? _self.xpTotal : xpTotal // ignore: cast_nullable_to_non_nullable
as int,nivel: null == nivel ? _self.nivel : nivel // ignore: cast_nullable_to_non_nullable
as int,etapas: null == etapas ? _self.etapas : etapas // ignore: cast_nullable_to_non_nullable
as List<JourneyStageDto>,retos: null == retos ? _self.retos : retos // ignore: cast_nullable_to_non_nullable
as List<JourneyChallengeDto>,
  ));
}

}


/// Adds pattern-matching-related methods to [JourneyDto].
extension JourneyDtoPatterns on JourneyDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JourneyDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JourneyDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JourneyDto value)  $default,){
final _that = this;
switch (_that) {
case _JourneyDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JourneyDto value)?  $default,){
final _that = this;
switch (_that) {
case _JourneyDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'emprendimiento_id')  int emprendimientoId, @JsonKey(name: 'xp_total')  int xpTotal,  int nivel,  List<JourneyStageDto> etapas,  List<JourneyChallengeDto> retos)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JourneyDto() when $default != null:
return $default(_that.emprendimientoId,_that.xpTotal,_that.nivel,_that.etapas,_that.retos);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'emprendimiento_id')  int emprendimientoId, @JsonKey(name: 'xp_total')  int xpTotal,  int nivel,  List<JourneyStageDto> etapas,  List<JourneyChallengeDto> retos)  $default,) {final _that = this;
switch (_that) {
case _JourneyDto():
return $default(_that.emprendimientoId,_that.xpTotal,_that.nivel,_that.etapas,_that.retos);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'emprendimiento_id')  int emprendimientoId, @JsonKey(name: 'xp_total')  int xpTotal,  int nivel,  List<JourneyStageDto> etapas,  List<JourneyChallengeDto> retos)?  $default,) {final _that = this;
switch (_that) {
case _JourneyDto() when $default != null:
return $default(_that.emprendimientoId,_that.xpTotal,_that.nivel,_that.etapas,_that.retos);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _JourneyDto extends JourneyDto {
  const _JourneyDto({@JsonKey(name: 'emprendimiento_id') required this.emprendimientoId, @JsonKey(name: 'xp_total') required this.xpTotal, required this.nivel, required  List<JourneyStageDto> etapas, required  List<JourneyChallengeDto> retos}): _etapas = etapas,_retos = retos,super._();
  factory _JourneyDto.fromJson(Map<String, dynamic> json) => _$JourneyDtoFromJson(json);

@override@JsonKey(name: 'emprendimiento_id') final  int emprendimientoId;
@override@JsonKey(name: 'xp_total') final  int xpTotal;
@override final  int nivel;
 final  List<JourneyStageDto> _etapas;
@override List<JourneyStageDto> get etapas {
  if (_etapas is EqualUnmodifiableListView) return _etapas;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_etapas);
}

 final  List<JourneyChallengeDto> _retos;
@override List<JourneyChallengeDto> get retos {
  if (_retos is EqualUnmodifiableListView) return _retos;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_retos);
}


/// Create a copy of JourneyDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JourneyDtoCopyWith<_JourneyDto> get copyWith => __$JourneyDtoCopyWithImpl<_JourneyDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$JourneyDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _JourneyDto&&(identical(other.emprendimientoId, emprendimientoId) || other.emprendimientoId == emprendimientoId)&&(identical(other.xpTotal, xpTotal) || other.xpTotal == xpTotal)&&(identical(other.nivel, nivel) || other.nivel == nivel)&&const DeepCollectionEquality().equals(other.etapas, _etapas)&&const DeepCollectionEquality().equals(other.retos, _retos));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,emprendimientoId,xpTotal,nivel,const DeepCollectionEquality().hash(_etapas),const DeepCollectionEquality().hash(_retos));
}

@override
String toString() {
    return 'JourneyDto(emprendimientoId: $emprendimientoId, xpTotal: $xpTotal, nivel: $nivel, etapas: $etapas, retos: $retos)';
}


}

/// @nodoc
abstract mixin class _$JourneyDtoCopyWith<$Res> implements $JourneyDtoCopyWith<$Res> {
  factory _$JourneyDtoCopyWith(_JourneyDto value, $Res Function(_JourneyDto) _then) = __$JourneyDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'emprendimiento_id') int emprendimientoId,@JsonKey(name: 'xp_total') int xpTotal, int nivel, List<JourneyStageDto> etapas, List<JourneyChallengeDto> retos
});




}
/// @nodoc
class __$JourneyDtoCopyWithImpl<$Res>
    implements _$JourneyDtoCopyWith<$Res> {
  __$JourneyDtoCopyWithImpl(this._self, this._then);

  final _JourneyDto _self;
  final $Res Function(_JourneyDto) _then;

/// Create a copy of JourneyDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? emprendimientoId = null,Object? xpTotal = null,Object? nivel = null,Object? etapas = null,Object? retos = null,}) {
  return _then(_JourneyDto(
emprendimientoId: null == emprendimientoId ? _self.emprendimientoId : emprendimientoId // ignore: cast_nullable_to_non_nullable
as int,xpTotal: null == xpTotal ? _self.xpTotal : xpTotal // ignore: cast_nullable_to_non_nullable
as int,nivel: null == nivel ? _self.nivel : nivel // ignore: cast_nullable_to_non_nullable
as int,etapas: null == etapas ? _self._etapas : etapas // ignore: cast_nullable_to_non_nullable
as List<JourneyStageDto>,retos: null == retos ? _self._retos : retos // ignore: cast_nullable_to_non_nullable
as List<JourneyChallengeDto>,
  ));
}


}

// dart format on
