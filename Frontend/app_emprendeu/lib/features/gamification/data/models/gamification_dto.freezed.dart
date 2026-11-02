// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'gamification_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CompletionDto {

@JsonKey(name: 'reto_id') int get retoId;@JsonKey(name: 'xp_otorgado') int get xpOtorgado;@JsonKey(name: 'xp_total') int get xpTotal; int get nivel;@JsonKey(name: 'subio_de_nivel') bool get subioDeNivel;@JsonKey(name: 'insignias_nuevas') List<String> get insigniasNuevas;
/// Create a copy of CompletionDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CompletionDtoCopyWith<CompletionDto> get copyWith => _$CompletionDtoCopyWithImpl<CompletionDto>(this as CompletionDto, _$identity);

  /// Serializes this CompletionDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CompletionDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CompletionDto&&(identical(other.retoId, _this.retoId) || other.retoId == _this.retoId)&&(identical(other.xpOtorgado, _this.xpOtorgado) || other.xpOtorgado == _this.xpOtorgado)&&(identical(other.xpTotal, _this.xpTotal) || other.xpTotal == _this.xpTotal)&&(identical(other.nivel, _this.nivel) || other.nivel == _this.nivel)&&(identical(other.subioDeNivel, _this.subioDeNivel) || other.subioDeNivel == _this.subioDeNivel)&&const DeepCollectionEquality().equals(other.insigniasNuevas, _this.insigniasNuevas));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CompletionDto;
  return Object.hash(runtimeType,_this.retoId,_this.xpOtorgado,_this.xpTotal,_this.nivel,_this.subioDeNivel,const DeepCollectionEquality().hash(_this.insigniasNuevas));
}

@override
String toString() {
  final _this = this as CompletionDto;
  return 'CompletionDto(retoId: ${_this.retoId}, xpOtorgado: ${_this.xpOtorgado}, xpTotal: ${_this.xpTotal}, nivel: ${_this.nivel}, subioDeNivel: ${_this.subioDeNivel}, insigniasNuevas: ${_this.insigniasNuevas})';
}


}

/// @nodoc
abstract mixin class $CompletionDtoCopyWith<$Res>  {
  factory $CompletionDtoCopyWith(CompletionDto value, $Res Function(CompletionDto) _then) = _$CompletionDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'reto_id') int retoId,@JsonKey(name: 'xp_otorgado') int xpOtorgado,@JsonKey(name: 'xp_total') int xpTotal, int nivel,@JsonKey(name: 'subio_de_nivel') bool subioDeNivel,@JsonKey(name: 'insignias_nuevas') List<String> insigniasNuevas
});




}
/// @nodoc
class _$CompletionDtoCopyWithImpl<$Res>
    implements $CompletionDtoCopyWith<$Res> {
  _$CompletionDtoCopyWithImpl(this._self, this._then);

  final CompletionDto _self;
  final $Res Function(CompletionDto) _then;

/// Create a copy of CompletionDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? retoId = null,Object? xpOtorgado = null,Object? xpTotal = null,Object? nivel = null,Object? subioDeNivel = null,Object? insigniasNuevas = null,}) {
  return _then(CompletionDto(
retoId: null == retoId ? _self.retoId : retoId // ignore: cast_nullable_to_non_nullable
as int,xpOtorgado: null == xpOtorgado ? _self.xpOtorgado : xpOtorgado // ignore: cast_nullable_to_non_nullable
as int,xpTotal: null == xpTotal ? _self.xpTotal : xpTotal // ignore: cast_nullable_to_non_nullable
as int,nivel: null == nivel ? _self.nivel : nivel // ignore: cast_nullable_to_non_nullable
as int,subioDeNivel: null == subioDeNivel ? _self.subioDeNivel : subioDeNivel // ignore: cast_nullable_to_non_nullable
as bool,insigniasNuevas: null == insigniasNuevas ? _self.insigniasNuevas : insigniasNuevas // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [CompletionDto].
extension CompletionDtoPatterns on CompletionDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CompletionDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CompletionDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CompletionDto value)  $default,){
final _that = this;
switch (_that) {
case _CompletionDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CompletionDto value)?  $default,){
final _that = this;
switch (_that) {
case _CompletionDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'reto_id')  int retoId, @JsonKey(name: 'xp_otorgado')  int xpOtorgado, @JsonKey(name: 'xp_total')  int xpTotal,  int nivel, @JsonKey(name: 'subio_de_nivel')  bool subioDeNivel, @JsonKey(name: 'insignias_nuevas')  List<String> insigniasNuevas)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CompletionDto() when $default != null:
return $default(_that.retoId,_that.xpOtorgado,_that.xpTotal,_that.nivel,_that.subioDeNivel,_that.insigniasNuevas);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'reto_id')  int retoId, @JsonKey(name: 'xp_otorgado')  int xpOtorgado, @JsonKey(name: 'xp_total')  int xpTotal,  int nivel, @JsonKey(name: 'subio_de_nivel')  bool subioDeNivel, @JsonKey(name: 'insignias_nuevas')  List<String> insigniasNuevas)  $default,) {final _that = this;
switch (_that) {
case _CompletionDto():
return $default(_that.retoId,_that.xpOtorgado,_that.xpTotal,_that.nivel,_that.subioDeNivel,_that.insigniasNuevas);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'reto_id')  int retoId, @JsonKey(name: 'xp_otorgado')  int xpOtorgado, @JsonKey(name: 'xp_total')  int xpTotal,  int nivel, @JsonKey(name: 'subio_de_nivel')  bool subioDeNivel, @JsonKey(name: 'insignias_nuevas')  List<String> insigniasNuevas)?  $default,) {final _that = this;
switch (_that) {
case _CompletionDto() when $default != null:
return $default(_that.retoId,_that.xpOtorgado,_that.xpTotal,_that.nivel,_that.subioDeNivel,_that.insigniasNuevas);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CompletionDto extends CompletionDto {
  const _CompletionDto({@JsonKey(name: 'reto_id') required this.retoId, @JsonKey(name: 'xp_otorgado') required this.xpOtorgado, @JsonKey(name: 'xp_total') required this.xpTotal, required this.nivel, @JsonKey(name: 'subio_de_nivel') required this.subioDeNivel, @JsonKey(name: 'insignias_nuevas')  List<String> insigniasNuevas = const <String>[]}): _insigniasNuevas = insigniasNuevas,super._();
  factory _CompletionDto.fromJson(Map<String, dynamic> json) => _$CompletionDtoFromJson(json);

@override@JsonKey(name: 'reto_id') final  int retoId;
@override@JsonKey(name: 'xp_otorgado') final  int xpOtorgado;
@override@JsonKey(name: 'xp_total') final  int xpTotal;
@override final  int nivel;
@override@JsonKey(name: 'subio_de_nivel') final  bool subioDeNivel;
 final  List<String> _insigniasNuevas;
@override@JsonKey(name: 'insignias_nuevas') List<String> get insigniasNuevas {
  if (_insigniasNuevas is EqualUnmodifiableListView) return _insigniasNuevas;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_insigniasNuevas);
}


/// Create a copy of CompletionDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CompletionDtoCopyWith<_CompletionDto> get copyWith => __$CompletionDtoCopyWithImpl<_CompletionDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CompletionDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CompletionDto&&(identical(other.retoId, retoId) || other.retoId == retoId)&&(identical(other.xpOtorgado, xpOtorgado) || other.xpOtorgado == xpOtorgado)&&(identical(other.xpTotal, xpTotal) || other.xpTotal == xpTotal)&&(identical(other.nivel, nivel) || other.nivel == nivel)&&(identical(other.subioDeNivel, subioDeNivel) || other.subioDeNivel == subioDeNivel)&&const DeepCollectionEquality().equals(other.insigniasNuevas, _insigniasNuevas));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,retoId,xpOtorgado,xpTotal,nivel,subioDeNivel,const DeepCollectionEquality().hash(_insigniasNuevas));
}

@override
String toString() {
    return 'CompletionDto(retoId: $retoId, xpOtorgado: $xpOtorgado, xpTotal: $xpTotal, nivel: $nivel, subioDeNivel: $subioDeNivel, insigniasNuevas: $insigniasNuevas)';
}


}

/// @nodoc
abstract mixin class _$CompletionDtoCopyWith<$Res> implements $CompletionDtoCopyWith<$Res> {
  factory _$CompletionDtoCopyWith(_CompletionDto value, $Res Function(_CompletionDto) _then) = __$CompletionDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'reto_id') int retoId,@JsonKey(name: 'xp_otorgado') int xpOtorgado,@JsonKey(name: 'xp_total') int xpTotal, int nivel,@JsonKey(name: 'subio_de_nivel') bool subioDeNivel,@JsonKey(name: 'insignias_nuevas') List<String> insigniasNuevas
});




}
/// @nodoc
class __$CompletionDtoCopyWithImpl<$Res>
    implements _$CompletionDtoCopyWith<$Res> {
  __$CompletionDtoCopyWithImpl(this._self, this._then);

  final _CompletionDto _self;
  final $Res Function(_CompletionDto) _then;

/// Create a copy of CompletionDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? retoId = null,Object? xpOtorgado = null,Object? xpTotal = null,Object? nivel = null,Object? subioDeNivel = null,Object? insigniasNuevas = null,}) {
  return _then(_CompletionDto(
retoId: null == retoId ? _self.retoId : retoId // ignore: cast_nullable_to_non_nullable
as int,xpOtorgado: null == xpOtorgado ? _self.xpOtorgado : xpOtorgado // ignore: cast_nullable_to_non_nullable
as int,xpTotal: null == xpTotal ? _self.xpTotal : xpTotal // ignore: cast_nullable_to_non_nullable
as int,nivel: null == nivel ? _self.nivel : nivel // ignore: cast_nullable_to_non_nullable
as int,subioDeNivel: null == subioDeNivel ? _self.subioDeNivel : subioDeNivel // ignore: cast_nullable_to_non_nullable
as bool,insigniasNuevas: null == insigniasNuevas ? _self._insigniasNuevas : insigniasNuevas // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$BadgeProgressDto {

@JsonKey(name: 'insignia_id') int get insigniaId; String get nombre; String? get criterio;@JsonKey(name: 'xp_recompensa') int get xpRecompensa; bool get obtenida;@JsonKey(name: 'fecha_obtenida') DateTime? get fechaObtenida;
/// Create a copy of BadgeProgressDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BadgeProgressDtoCopyWith<BadgeProgressDto> get copyWith => _$BadgeProgressDtoCopyWithImpl<BadgeProgressDto>(this as BadgeProgressDto, _$identity);

  /// Serializes this BadgeProgressDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BadgeProgressDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BadgeProgressDto&&(identical(other.insigniaId, _this.insigniaId) || other.insigniaId == _this.insigniaId)&&(identical(other.nombre, _this.nombre) || other.nombre == _this.nombre)&&(identical(other.criterio, _this.criterio) || other.criterio == _this.criterio)&&(identical(other.xpRecompensa, _this.xpRecompensa) || other.xpRecompensa == _this.xpRecompensa)&&(identical(other.obtenida, _this.obtenida) || other.obtenida == _this.obtenida)&&(identical(other.fechaObtenida, _this.fechaObtenida) || other.fechaObtenida == _this.fechaObtenida));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BadgeProgressDto;
  return Object.hash(runtimeType,_this.insigniaId,_this.nombre,_this.criterio,_this.xpRecompensa,_this.obtenida,_this.fechaObtenida);
}

@override
String toString() {
  final _this = this as BadgeProgressDto;
  return 'BadgeProgressDto(insigniaId: ${_this.insigniaId}, nombre: ${_this.nombre}, criterio: ${_this.criterio}, xpRecompensa: ${_this.xpRecompensa}, obtenida: ${_this.obtenida}, fechaObtenida: ${_this.fechaObtenida})';
}


}

/// @nodoc
abstract mixin class $BadgeProgressDtoCopyWith<$Res>  {
  factory $BadgeProgressDtoCopyWith(BadgeProgressDto value, $Res Function(BadgeProgressDto) _then) = _$BadgeProgressDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'insignia_id') int insigniaId, String nombre, String? criterio,@JsonKey(name: 'xp_recompensa') int xpRecompensa, bool obtenida,@JsonKey(name: 'fecha_obtenida') DateTime? fechaObtenida
});




}
/// @nodoc
class _$BadgeProgressDtoCopyWithImpl<$Res>
    implements $BadgeProgressDtoCopyWith<$Res> {
  _$BadgeProgressDtoCopyWithImpl(this._self, this._then);

  final BadgeProgressDto _self;
  final $Res Function(BadgeProgressDto) _then;

/// Create a copy of BadgeProgressDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? insigniaId = null,Object? nombre = null,Object? criterio = freezed,Object? xpRecompensa = null,Object? obtenida = null,Object? fechaObtenida = freezed,}) {
  return _then(BadgeProgressDto(
insigniaId: null == insigniaId ? _self.insigniaId : insigniaId // ignore: cast_nullable_to_non_nullable
as int,nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,criterio: freezed == criterio ? _self.criterio : criterio // ignore: cast_nullable_to_non_nullable
as String?,xpRecompensa: null == xpRecompensa ? _self.xpRecompensa : xpRecompensa // ignore: cast_nullable_to_non_nullable
as int,obtenida: null == obtenida ? _self.obtenida : obtenida // ignore: cast_nullable_to_non_nullable
as bool,fechaObtenida: freezed == fechaObtenida ? _self.fechaObtenida : fechaObtenida // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [BadgeProgressDto].
extension BadgeProgressDtoPatterns on BadgeProgressDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BadgeProgressDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BadgeProgressDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BadgeProgressDto value)  $default,){
final _that = this;
switch (_that) {
case _BadgeProgressDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BadgeProgressDto value)?  $default,){
final _that = this;
switch (_that) {
case _BadgeProgressDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'insignia_id')  int insigniaId,  String nombre,  String? criterio, @JsonKey(name: 'xp_recompensa')  int xpRecompensa,  bool obtenida, @JsonKey(name: 'fecha_obtenida')  DateTime? fechaObtenida)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BadgeProgressDto() when $default != null:
return $default(_that.insigniaId,_that.nombre,_that.criterio,_that.xpRecompensa,_that.obtenida,_that.fechaObtenida);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'insignia_id')  int insigniaId,  String nombre,  String? criterio, @JsonKey(name: 'xp_recompensa')  int xpRecompensa,  bool obtenida, @JsonKey(name: 'fecha_obtenida')  DateTime? fechaObtenida)  $default,) {final _that = this;
switch (_that) {
case _BadgeProgressDto():
return $default(_that.insigniaId,_that.nombre,_that.criterio,_that.xpRecompensa,_that.obtenida,_that.fechaObtenida);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'insignia_id')  int insigniaId,  String nombre,  String? criterio, @JsonKey(name: 'xp_recompensa')  int xpRecompensa,  bool obtenida, @JsonKey(name: 'fecha_obtenida')  DateTime? fechaObtenida)?  $default,) {final _that = this;
switch (_that) {
case _BadgeProgressDto() when $default != null:
return $default(_that.insigniaId,_that.nombre,_that.criterio,_that.xpRecompensa,_that.obtenida,_that.fechaObtenida);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BadgeProgressDto extends BadgeProgressDto {
  const _BadgeProgressDto({@JsonKey(name: 'insignia_id') required this.insigniaId, required this.nombre, this.criterio, @JsonKey(name: 'xp_recompensa') this.xpRecompensa = 0, this.obtenida = false, @JsonKey(name: 'fecha_obtenida') this.fechaObtenida}): super._();
  factory _BadgeProgressDto.fromJson(Map<String, dynamic> json) => _$BadgeProgressDtoFromJson(json);

@override@JsonKey(name: 'insignia_id') final  int insigniaId;
@override final  String nombre;
@override final  String? criterio;
@override@JsonKey(name: 'xp_recompensa') final  int xpRecompensa;
@override@JsonKey() final  bool obtenida;
@override@JsonKey(name: 'fecha_obtenida') final  DateTime? fechaObtenida;

/// Create a copy of BadgeProgressDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BadgeProgressDtoCopyWith<_BadgeProgressDto> get copyWith => __$BadgeProgressDtoCopyWithImpl<_BadgeProgressDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BadgeProgressDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BadgeProgressDto&&(identical(other.insigniaId, insigniaId) || other.insigniaId == insigniaId)&&(identical(other.nombre, nombre) || other.nombre == nombre)&&(identical(other.criterio, criterio) || other.criterio == criterio)&&(identical(other.xpRecompensa, xpRecompensa) || other.xpRecompensa == xpRecompensa)&&(identical(other.obtenida, obtenida) || other.obtenida == obtenida)&&(identical(other.fechaObtenida, fechaObtenida) || other.fechaObtenida == fechaObtenida));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,insigniaId,nombre,criterio,xpRecompensa,obtenida,fechaObtenida);
}

@override
String toString() {
    return 'BadgeProgressDto(insigniaId: $insigniaId, nombre: $nombre, criterio: $criterio, xpRecompensa: $xpRecompensa, obtenida: $obtenida, fechaObtenida: $fechaObtenida)';
}


}

/// @nodoc
abstract mixin class _$BadgeProgressDtoCopyWith<$Res> implements $BadgeProgressDtoCopyWith<$Res> {
  factory _$BadgeProgressDtoCopyWith(_BadgeProgressDto value, $Res Function(_BadgeProgressDto) _then) = __$BadgeProgressDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'insignia_id') int insigniaId, String nombre, String? criterio,@JsonKey(name: 'xp_recompensa') int xpRecompensa, bool obtenida,@JsonKey(name: 'fecha_obtenida') DateTime? fechaObtenida
});




}
/// @nodoc
class __$BadgeProgressDtoCopyWithImpl<$Res>
    implements _$BadgeProgressDtoCopyWith<$Res> {
  __$BadgeProgressDtoCopyWithImpl(this._self, this._then);

  final _BadgeProgressDto _self;
  final $Res Function(_BadgeProgressDto) _then;

/// Create a copy of BadgeProgressDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? insigniaId = null,Object? nombre = null,Object? criterio = freezed,Object? xpRecompensa = null,Object? obtenida = null,Object? fechaObtenida = freezed,}) {
  return _then(_BadgeProgressDto(
insigniaId: null == insigniaId ? _self.insigniaId : insigniaId // ignore: cast_nullable_to_non_nullable
as int,nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,criterio: freezed == criterio ? _self.criterio : criterio // ignore: cast_nullable_to_non_nullable
as String?,xpRecompensa: null == xpRecompensa ? _self.xpRecompensa : xpRecompensa // ignore: cast_nullable_to_non_nullable
as int,obtenida: null == obtenida ? _self.obtenida : obtenida // ignore: cast_nullable_to_non_nullable
as bool,fechaObtenida: freezed == fechaObtenida ? _self.fechaObtenida : fechaObtenida // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$XpMovementDto {

 String? get motivo; int get cantidad; DateTime? get fecha;
/// Create a copy of XpMovementDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$XpMovementDtoCopyWith<XpMovementDto> get copyWith => _$XpMovementDtoCopyWithImpl<XpMovementDto>(this as XpMovementDto, _$identity);

  /// Serializes this XpMovementDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as XpMovementDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is XpMovementDto&&(identical(other.motivo, _this.motivo) || other.motivo == _this.motivo)&&(identical(other.cantidad, _this.cantidad) || other.cantidad == _this.cantidad)&&(identical(other.fecha, _this.fecha) || other.fecha == _this.fecha));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as XpMovementDto;
  return Object.hash(runtimeType,_this.motivo,_this.cantidad,_this.fecha);
}

@override
String toString() {
  final _this = this as XpMovementDto;
  return 'XpMovementDto(motivo: ${_this.motivo}, cantidad: ${_this.cantidad}, fecha: ${_this.fecha})';
}


}

/// @nodoc
abstract mixin class $XpMovementDtoCopyWith<$Res>  {
  factory $XpMovementDtoCopyWith(XpMovementDto value, $Res Function(XpMovementDto) _then) = _$XpMovementDtoCopyWithImpl;
@useResult
$Res call({
 String? motivo, int cantidad, DateTime? fecha
});




}
/// @nodoc
class _$XpMovementDtoCopyWithImpl<$Res>
    implements $XpMovementDtoCopyWith<$Res> {
  _$XpMovementDtoCopyWithImpl(this._self, this._then);

  final XpMovementDto _self;
  final $Res Function(XpMovementDto) _then;

/// Create a copy of XpMovementDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? motivo = freezed,Object? cantidad = null,Object? fecha = freezed,}) {
  return _then(XpMovementDto(
motivo: freezed == motivo ? _self.motivo : motivo // ignore: cast_nullable_to_non_nullable
as String?,cantidad: null == cantidad ? _self.cantidad : cantidad // ignore: cast_nullable_to_non_nullable
as int,fecha: freezed == fecha ? _self.fecha : fecha // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [XpMovementDto].
extension XpMovementDtoPatterns on XpMovementDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _XpMovementDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _XpMovementDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _XpMovementDto value)  $default,){
final _that = this;
switch (_that) {
case _XpMovementDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _XpMovementDto value)?  $default,){
final _that = this;
switch (_that) {
case _XpMovementDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? motivo,  int cantidad,  DateTime? fecha)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _XpMovementDto() when $default != null:
return $default(_that.motivo,_that.cantidad,_that.fecha);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? motivo,  int cantidad,  DateTime? fecha)  $default,) {final _that = this;
switch (_that) {
case _XpMovementDto():
return $default(_that.motivo,_that.cantidad,_that.fecha);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? motivo,  int cantidad,  DateTime? fecha)?  $default,) {final _that = this;
switch (_that) {
case _XpMovementDto() when $default != null:
return $default(_that.motivo,_that.cantidad,_that.fecha);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _XpMovementDto extends XpMovementDto {
  const _XpMovementDto({this.motivo, required this.cantidad, this.fecha}): super._();
  factory _XpMovementDto.fromJson(Map<String, dynamic> json) => _$XpMovementDtoFromJson(json);

@override final  String? motivo;
@override final  int cantidad;
@override final  DateTime? fecha;

/// Create a copy of XpMovementDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$XpMovementDtoCopyWith<_XpMovementDto> get copyWith => __$XpMovementDtoCopyWithImpl<_XpMovementDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$XpMovementDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _XpMovementDto&&(identical(other.motivo, motivo) || other.motivo == motivo)&&(identical(other.cantidad, cantidad) || other.cantidad == cantidad)&&(identical(other.fecha, fecha) || other.fecha == fecha));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,motivo,cantidad,fecha);
}

@override
String toString() {
    return 'XpMovementDto(motivo: $motivo, cantidad: $cantidad, fecha: $fecha)';
}


}

/// @nodoc
abstract mixin class _$XpMovementDtoCopyWith<$Res> implements $XpMovementDtoCopyWith<$Res> {
  factory _$XpMovementDtoCopyWith(_XpMovementDto value, $Res Function(_XpMovementDto) _then) = __$XpMovementDtoCopyWithImpl;
@override @useResult
$Res call({
 String? motivo, int cantidad, DateTime? fecha
});




}
/// @nodoc
class __$XpMovementDtoCopyWithImpl<$Res>
    implements _$XpMovementDtoCopyWith<$Res> {
  __$XpMovementDtoCopyWithImpl(this._self, this._then);

  final _XpMovementDto _self;
  final $Res Function(_XpMovementDto) _then;

/// Create a copy of XpMovementDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? motivo = freezed,Object? cantidad = null,Object? fecha = freezed,}) {
  return _then(_XpMovementDto(
motivo: freezed == motivo ? _self.motivo : motivo // ignore: cast_nullable_to_non_nullable
as String?,cantidad: null == cantidad ? _self.cantidad : cantidad // ignore: cast_nullable_to_non_nullable
as int,fecha: freezed == fecha ? _self.fecha : fecha // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$GamificationProfileDto {

@JsonKey(name: 'xp_total') int get xpTotal; int get nivel;@JsonKey(name: 'xp_siguiente_nivel') int? get xpSiguienteNivel;@JsonKey(name: 'xp_faltante') int? get xpFaltante;@JsonKey(name: 'progreso_pct') double get progresoPct; List<BadgeProgressDto> get insignias; List<XpMovementDto> get historial;
/// Create a copy of GamificationProfileDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GamificationProfileDtoCopyWith<GamificationProfileDto> get copyWith => _$GamificationProfileDtoCopyWithImpl<GamificationProfileDto>(this as GamificationProfileDto, _$identity);

  /// Serializes this GamificationProfileDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as GamificationProfileDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GamificationProfileDto&&(identical(other.xpTotal, _this.xpTotal) || other.xpTotal == _this.xpTotal)&&(identical(other.nivel, _this.nivel) || other.nivel == _this.nivel)&&(identical(other.xpSiguienteNivel, _this.xpSiguienteNivel) || other.xpSiguienteNivel == _this.xpSiguienteNivel)&&(identical(other.xpFaltante, _this.xpFaltante) || other.xpFaltante == _this.xpFaltante)&&(identical(other.progresoPct, _this.progresoPct) || other.progresoPct == _this.progresoPct)&&const DeepCollectionEquality().equals(other.insignias, _this.insignias)&&const DeepCollectionEquality().equals(other.historial, _this.historial));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as GamificationProfileDto;
  return Object.hash(runtimeType,_this.xpTotal,_this.nivel,_this.xpSiguienteNivel,_this.xpFaltante,_this.progresoPct,const DeepCollectionEquality().hash(_this.insignias),const DeepCollectionEquality().hash(_this.historial));
}

@override
String toString() {
  final _this = this as GamificationProfileDto;
  return 'GamificationProfileDto(xpTotal: ${_this.xpTotal}, nivel: ${_this.nivel}, xpSiguienteNivel: ${_this.xpSiguienteNivel}, xpFaltante: ${_this.xpFaltante}, progresoPct: ${_this.progresoPct}, insignias: ${_this.insignias}, historial: ${_this.historial})';
}


}

/// @nodoc
abstract mixin class $GamificationProfileDtoCopyWith<$Res>  {
  factory $GamificationProfileDtoCopyWith(GamificationProfileDto value, $Res Function(GamificationProfileDto) _then) = _$GamificationProfileDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'xp_total') int xpTotal, int nivel,@JsonKey(name: 'xp_siguiente_nivel') int? xpSiguienteNivel,@JsonKey(name: 'xp_faltante') int? xpFaltante,@JsonKey(name: 'progreso_pct') double progresoPct, List<BadgeProgressDto> insignias, List<XpMovementDto> historial
});




}
/// @nodoc
class _$GamificationProfileDtoCopyWithImpl<$Res>
    implements $GamificationProfileDtoCopyWith<$Res> {
  _$GamificationProfileDtoCopyWithImpl(this._self, this._then);

  final GamificationProfileDto _self;
  final $Res Function(GamificationProfileDto) _then;

/// Create a copy of GamificationProfileDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? xpTotal = null,Object? nivel = null,Object? xpSiguienteNivel = freezed,Object? xpFaltante = freezed,Object? progresoPct = null,Object? insignias = null,Object? historial = null,}) {
  return _then(GamificationProfileDto(
xpTotal: null == xpTotal ? _self.xpTotal : xpTotal // ignore: cast_nullable_to_non_nullable
as int,nivel: null == nivel ? _self.nivel : nivel // ignore: cast_nullable_to_non_nullable
as int,xpSiguienteNivel: freezed == xpSiguienteNivel ? _self.xpSiguienteNivel : xpSiguienteNivel // ignore: cast_nullable_to_non_nullable
as int?,xpFaltante: freezed == xpFaltante ? _self.xpFaltante : xpFaltante // ignore: cast_nullable_to_non_nullable
as int?,progresoPct: null == progresoPct ? _self.progresoPct : progresoPct // ignore: cast_nullable_to_non_nullable
as double,insignias: null == insignias ? _self.insignias : insignias // ignore: cast_nullable_to_non_nullable
as List<BadgeProgressDto>,historial: null == historial ? _self.historial : historial // ignore: cast_nullable_to_non_nullable
as List<XpMovementDto>,
  ));
}

}


/// Adds pattern-matching-related methods to [GamificationProfileDto].
extension GamificationProfileDtoPatterns on GamificationProfileDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GamificationProfileDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GamificationProfileDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GamificationProfileDto value)  $default,){
final _that = this;
switch (_that) {
case _GamificationProfileDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GamificationProfileDto value)?  $default,){
final _that = this;
switch (_that) {
case _GamificationProfileDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'xp_total')  int xpTotal,  int nivel, @JsonKey(name: 'xp_siguiente_nivel')  int? xpSiguienteNivel, @JsonKey(name: 'xp_faltante')  int? xpFaltante, @JsonKey(name: 'progreso_pct')  double progresoPct,  List<BadgeProgressDto> insignias,  List<XpMovementDto> historial)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GamificationProfileDto() when $default != null:
return $default(_that.xpTotal,_that.nivel,_that.xpSiguienteNivel,_that.xpFaltante,_that.progresoPct,_that.insignias,_that.historial);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'xp_total')  int xpTotal,  int nivel, @JsonKey(name: 'xp_siguiente_nivel')  int? xpSiguienteNivel, @JsonKey(name: 'xp_faltante')  int? xpFaltante, @JsonKey(name: 'progreso_pct')  double progresoPct,  List<BadgeProgressDto> insignias,  List<XpMovementDto> historial)  $default,) {final _that = this;
switch (_that) {
case _GamificationProfileDto():
return $default(_that.xpTotal,_that.nivel,_that.xpSiguienteNivel,_that.xpFaltante,_that.progresoPct,_that.insignias,_that.historial);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'xp_total')  int xpTotal,  int nivel, @JsonKey(name: 'xp_siguiente_nivel')  int? xpSiguienteNivel, @JsonKey(name: 'xp_faltante')  int? xpFaltante, @JsonKey(name: 'progreso_pct')  double progresoPct,  List<BadgeProgressDto> insignias,  List<XpMovementDto> historial)?  $default,) {final _that = this;
switch (_that) {
case _GamificationProfileDto() when $default != null:
return $default(_that.xpTotal,_that.nivel,_that.xpSiguienteNivel,_that.xpFaltante,_that.progresoPct,_that.insignias,_that.historial);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GamificationProfileDto extends GamificationProfileDto {
  const _GamificationProfileDto({@JsonKey(name: 'xp_total') required this.xpTotal, required this.nivel, @JsonKey(name: 'xp_siguiente_nivel') this.xpSiguienteNivel, @JsonKey(name: 'xp_faltante') this.xpFaltante, @JsonKey(name: 'progreso_pct') required this.progresoPct,  List<BadgeProgressDto> insignias = const <BadgeProgressDto>[],  List<XpMovementDto> historial = const <XpMovementDto>[]}): _insignias = insignias,_historial = historial,super._();
  factory _GamificationProfileDto.fromJson(Map<String, dynamic> json) => _$GamificationProfileDtoFromJson(json);

@override@JsonKey(name: 'xp_total') final  int xpTotal;
@override final  int nivel;
@override@JsonKey(name: 'xp_siguiente_nivel') final  int? xpSiguienteNivel;
@override@JsonKey(name: 'xp_faltante') final  int? xpFaltante;
@override@JsonKey(name: 'progreso_pct') final  double progresoPct;
 final  List<BadgeProgressDto> _insignias;
@override@JsonKey() List<BadgeProgressDto> get insignias {
  if (_insignias is EqualUnmodifiableListView) return _insignias;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_insignias);
}

 final  List<XpMovementDto> _historial;
@override@JsonKey() List<XpMovementDto> get historial {
  if (_historial is EqualUnmodifiableListView) return _historial;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_historial);
}


/// Create a copy of GamificationProfileDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GamificationProfileDtoCopyWith<_GamificationProfileDto> get copyWith => __$GamificationProfileDtoCopyWithImpl<_GamificationProfileDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GamificationProfileDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GamificationProfileDto&&(identical(other.xpTotal, xpTotal) || other.xpTotal == xpTotal)&&(identical(other.nivel, nivel) || other.nivel == nivel)&&(identical(other.xpSiguienteNivel, xpSiguienteNivel) || other.xpSiguienteNivel == xpSiguienteNivel)&&(identical(other.xpFaltante, xpFaltante) || other.xpFaltante == xpFaltante)&&(identical(other.progresoPct, progresoPct) || other.progresoPct == progresoPct)&&const DeepCollectionEquality().equals(other.insignias, _insignias)&&const DeepCollectionEquality().equals(other.historial, _historial));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,xpTotal,nivel,xpSiguienteNivel,xpFaltante,progresoPct,const DeepCollectionEquality().hash(_insignias),const DeepCollectionEquality().hash(_historial));
}

@override
String toString() {
    return 'GamificationProfileDto(xpTotal: $xpTotal, nivel: $nivel, xpSiguienteNivel: $xpSiguienteNivel, xpFaltante: $xpFaltante, progresoPct: $progresoPct, insignias: $insignias, historial: $historial)';
}


}

/// @nodoc
abstract mixin class _$GamificationProfileDtoCopyWith<$Res> implements $GamificationProfileDtoCopyWith<$Res> {
  factory _$GamificationProfileDtoCopyWith(_GamificationProfileDto value, $Res Function(_GamificationProfileDto) _then) = __$GamificationProfileDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'xp_total') int xpTotal, int nivel,@JsonKey(name: 'xp_siguiente_nivel') int? xpSiguienteNivel,@JsonKey(name: 'xp_faltante') int? xpFaltante,@JsonKey(name: 'progreso_pct') double progresoPct, List<BadgeProgressDto> insignias, List<XpMovementDto> historial
});




}
/// @nodoc
class __$GamificationProfileDtoCopyWithImpl<$Res>
    implements _$GamificationProfileDtoCopyWith<$Res> {
  __$GamificationProfileDtoCopyWithImpl(this._self, this._then);

  final _GamificationProfileDto _self;
  final $Res Function(_GamificationProfileDto) _then;

/// Create a copy of GamificationProfileDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? xpTotal = null,Object? nivel = null,Object? xpSiguienteNivel = freezed,Object? xpFaltante = freezed,Object? progresoPct = null,Object? insignias = null,Object? historial = null,}) {
  return _then(_GamificationProfileDto(
xpTotal: null == xpTotal ? _self.xpTotal : xpTotal // ignore: cast_nullable_to_non_nullable
as int,nivel: null == nivel ? _self.nivel : nivel // ignore: cast_nullable_to_non_nullable
as int,xpSiguienteNivel: freezed == xpSiguienteNivel ? _self.xpSiguienteNivel : xpSiguienteNivel // ignore: cast_nullable_to_non_nullable
as int?,xpFaltante: freezed == xpFaltante ? _self.xpFaltante : xpFaltante // ignore: cast_nullable_to_non_nullable
as int?,progresoPct: null == progresoPct ? _self.progresoPct : progresoPct // ignore: cast_nullable_to_non_nullable
as double,insignias: null == insignias ? _self._insignias : insignias // ignore: cast_nullable_to_non_nullable
as List<BadgeProgressDto>,historial: null == historial ? _self._historial : historial // ignore: cast_nullable_to_non_nullable
as List<XpMovementDto>,
  ));
}


}

// dart format on
