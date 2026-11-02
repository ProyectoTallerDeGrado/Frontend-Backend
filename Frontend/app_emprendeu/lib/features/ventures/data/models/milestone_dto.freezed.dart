// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'milestone_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MilestoneDto {

@JsonKey(name: 'hito_id') int get hitoId; String get titulo; String? get descripcion; String? get estado;@JsonKey(name: 'fecha_estimada') DateTime? get fechaEstimada;@JsonKey(name: 'fecha_cumplimiento') DateTime? get fechaCumplimiento;
/// Create a copy of MilestoneDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MilestoneDtoCopyWith<MilestoneDto> get copyWith => _$MilestoneDtoCopyWithImpl<MilestoneDto>(this as MilestoneDto, _$identity);

  /// Serializes this MilestoneDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as MilestoneDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MilestoneDto&&(identical(other.hitoId, _this.hitoId) || other.hitoId == _this.hitoId)&&(identical(other.titulo, _this.titulo) || other.titulo == _this.titulo)&&(identical(other.descripcion, _this.descripcion) || other.descripcion == _this.descripcion)&&(identical(other.estado, _this.estado) || other.estado == _this.estado)&&(identical(other.fechaEstimada, _this.fechaEstimada) || other.fechaEstimada == _this.fechaEstimada)&&(identical(other.fechaCumplimiento, _this.fechaCumplimiento) || other.fechaCumplimiento == _this.fechaCumplimiento));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as MilestoneDto;
  return Object.hash(runtimeType,_this.hitoId,_this.titulo,_this.descripcion,_this.estado,_this.fechaEstimada,_this.fechaCumplimiento);
}

@override
String toString() {
  final _this = this as MilestoneDto;
  return 'MilestoneDto(hitoId: ${_this.hitoId}, titulo: ${_this.titulo}, descripcion: ${_this.descripcion}, estado: ${_this.estado}, fechaEstimada: ${_this.fechaEstimada}, fechaCumplimiento: ${_this.fechaCumplimiento})';
}


}

/// @nodoc
abstract mixin class $MilestoneDtoCopyWith<$Res>  {
  factory $MilestoneDtoCopyWith(MilestoneDto value, $Res Function(MilestoneDto) _then) = _$MilestoneDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'hito_id') int hitoId, String titulo, String? descripcion, String? estado,@JsonKey(name: 'fecha_estimada') DateTime? fechaEstimada,@JsonKey(name: 'fecha_cumplimiento') DateTime? fechaCumplimiento
});




}
/// @nodoc
class _$MilestoneDtoCopyWithImpl<$Res>
    implements $MilestoneDtoCopyWith<$Res> {
  _$MilestoneDtoCopyWithImpl(this._self, this._then);

  final MilestoneDto _self;
  final $Res Function(MilestoneDto) _then;

/// Create a copy of MilestoneDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? hitoId = null,Object? titulo = null,Object? descripcion = freezed,Object? estado = freezed,Object? fechaEstimada = freezed,Object? fechaCumplimiento = freezed,}) {
  return _then(MilestoneDto(
hitoId: null == hitoId ? _self.hitoId : hitoId // ignore: cast_nullable_to_non_nullable
as int,titulo: null == titulo ? _self.titulo : titulo // ignore: cast_nullable_to_non_nullable
as String,descripcion: freezed == descripcion ? _self.descripcion : descripcion // ignore: cast_nullable_to_non_nullable
as String?,estado: freezed == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as String?,fechaEstimada: freezed == fechaEstimada ? _self.fechaEstimada : fechaEstimada // ignore: cast_nullable_to_non_nullable
as DateTime?,fechaCumplimiento: freezed == fechaCumplimiento ? _self.fechaCumplimiento : fechaCumplimiento // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [MilestoneDto].
extension MilestoneDtoPatterns on MilestoneDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MilestoneDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MilestoneDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MilestoneDto value)  $default,){
final _that = this;
switch (_that) {
case _MilestoneDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MilestoneDto value)?  $default,){
final _that = this;
switch (_that) {
case _MilestoneDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'hito_id')  int hitoId,  String titulo,  String? descripcion,  String? estado, @JsonKey(name: 'fecha_estimada')  DateTime? fechaEstimada, @JsonKey(name: 'fecha_cumplimiento')  DateTime? fechaCumplimiento)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MilestoneDto() when $default != null:
return $default(_that.hitoId,_that.titulo,_that.descripcion,_that.estado,_that.fechaEstimada,_that.fechaCumplimiento);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'hito_id')  int hitoId,  String titulo,  String? descripcion,  String? estado, @JsonKey(name: 'fecha_estimada')  DateTime? fechaEstimada, @JsonKey(name: 'fecha_cumplimiento')  DateTime? fechaCumplimiento)  $default,) {final _that = this;
switch (_that) {
case _MilestoneDto():
return $default(_that.hitoId,_that.titulo,_that.descripcion,_that.estado,_that.fechaEstimada,_that.fechaCumplimiento);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'hito_id')  int hitoId,  String titulo,  String? descripcion,  String? estado, @JsonKey(name: 'fecha_estimada')  DateTime? fechaEstimada, @JsonKey(name: 'fecha_cumplimiento')  DateTime? fechaCumplimiento)?  $default,) {final _that = this;
switch (_that) {
case _MilestoneDto() when $default != null:
return $default(_that.hitoId,_that.titulo,_that.descripcion,_that.estado,_that.fechaEstimada,_that.fechaCumplimiento);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MilestoneDto extends MilestoneDto {
  const _MilestoneDto({@JsonKey(name: 'hito_id') required this.hitoId, required this.titulo, this.descripcion, this.estado, @JsonKey(name: 'fecha_estimada') this.fechaEstimada, @JsonKey(name: 'fecha_cumplimiento') this.fechaCumplimiento}): super._();
  factory _MilestoneDto.fromJson(Map<String, dynamic> json) => _$MilestoneDtoFromJson(json);

@override@JsonKey(name: 'hito_id') final  int hitoId;
@override final  String titulo;
@override final  String? descripcion;
@override final  String? estado;
@override@JsonKey(name: 'fecha_estimada') final  DateTime? fechaEstimada;
@override@JsonKey(name: 'fecha_cumplimiento') final  DateTime? fechaCumplimiento;

/// Create a copy of MilestoneDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MilestoneDtoCopyWith<_MilestoneDto> get copyWith => __$MilestoneDtoCopyWithImpl<_MilestoneDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MilestoneDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _MilestoneDto&&(identical(other.hitoId, hitoId) || other.hitoId == hitoId)&&(identical(other.titulo, titulo) || other.titulo == titulo)&&(identical(other.descripcion, descripcion) || other.descripcion == descripcion)&&(identical(other.estado, estado) || other.estado == estado)&&(identical(other.fechaEstimada, fechaEstimada) || other.fechaEstimada == fechaEstimada)&&(identical(other.fechaCumplimiento, fechaCumplimiento) || other.fechaCumplimiento == fechaCumplimiento));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,hitoId,titulo,descripcion,estado,fechaEstimada,fechaCumplimiento);
}

@override
String toString() {
    return 'MilestoneDto(hitoId: $hitoId, titulo: $titulo, descripcion: $descripcion, estado: $estado, fechaEstimada: $fechaEstimada, fechaCumplimiento: $fechaCumplimiento)';
}


}

/// @nodoc
abstract mixin class _$MilestoneDtoCopyWith<$Res> implements $MilestoneDtoCopyWith<$Res> {
  factory _$MilestoneDtoCopyWith(_MilestoneDto value, $Res Function(_MilestoneDto) _then) = __$MilestoneDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'hito_id') int hitoId, String titulo, String? descripcion, String? estado,@JsonKey(name: 'fecha_estimada') DateTime? fechaEstimada,@JsonKey(name: 'fecha_cumplimiento') DateTime? fechaCumplimiento
});




}
/// @nodoc
class __$MilestoneDtoCopyWithImpl<$Res>
    implements _$MilestoneDtoCopyWith<$Res> {
  __$MilestoneDtoCopyWithImpl(this._self, this._then);

  final _MilestoneDto _self;
  final $Res Function(_MilestoneDto) _then;

/// Create a copy of MilestoneDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? hitoId = null,Object? titulo = null,Object? descripcion = freezed,Object? estado = freezed,Object? fechaEstimada = freezed,Object? fechaCumplimiento = freezed,}) {
  return _then(_MilestoneDto(
hitoId: null == hitoId ? _self.hitoId : hitoId // ignore: cast_nullable_to_non_nullable
as int,titulo: null == titulo ? _self.titulo : titulo // ignore: cast_nullable_to_non_nullable
as String,descripcion: freezed == descripcion ? _self.descripcion : descripcion // ignore: cast_nullable_to_non_nullable
as String?,estado: freezed == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as String?,fechaEstimada: freezed == fechaEstimada ? _self.fechaEstimada : fechaEstimada // ignore: cast_nullable_to_non_nullable
as DateTime?,fechaCumplimiento: freezed == fechaCumplimiento ? _self.fechaCumplimiento : fechaCumplimiento // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
