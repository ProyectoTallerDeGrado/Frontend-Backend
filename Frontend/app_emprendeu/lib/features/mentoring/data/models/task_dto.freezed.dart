// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TaskDto {

 String get tipo;@JsonKey(name: 'referencia_id') int get referenciaId;@JsonKey(name: 'emprendimiento_id') int get emprendimientoId; String get titulo; String? get detalle; String? get responsable; String get estado;@JsonKey(name: 'fecha_prevista') DateTime? get fechaPrevista; bool get vencida;
/// Create a copy of TaskDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskDtoCopyWith<TaskDto> get copyWith => _$TaskDtoCopyWithImpl<TaskDto>(this as TaskDto, _$identity);

  /// Serializes this TaskDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as TaskDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskDto&&(identical(other.tipo, _this.tipo) || other.tipo == _this.tipo)&&(identical(other.referenciaId, _this.referenciaId) || other.referenciaId == _this.referenciaId)&&(identical(other.emprendimientoId, _this.emprendimientoId) || other.emprendimientoId == _this.emprendimientoId)&&(identical(other.titulo, _this.titulo) || other.titulo == _this.titulo)&&(identical(other.detalle, _this.detalle) || other.detalle == _this.detalle)&&(identical(other.responsable, _this.responsable) || other.responsable == _this.responsable)&&(identical(other.estado, _this.estado) || other.estado == _this.estado)&&(identical(other.fechaPrevista, _this.fechaPrevista) || other.fechaPrevista == _this.fechaPrevista)&&(identical(other.vencida, _this.vencida) || other.vencida == _this.vencida));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as TaskDto;
  return Object.hash(runtimeType,_this.tipo,_this.referenciaId,_this.emprendimientoId,_this.titulo,_this.detalle,_this.responsable,_this.estado,_this.fechaPrevista,_this.vencida);
}

@override
String toString() {
  final _this = this as TaskDto;
  return 'TaskDto(tipo: ${_this.tipo}, referenciaId: ${_this.referenciaId}, emprendimientoId: ${_this.emprendimientoId}, titulo: ${_this.titulo}, detalle: ${_this.detalle}, responsable: ${_this.responsable}, estado: ${_this.estado}, fechaPrevista: ${_this.fechaPrevista}, vencida: ${_this.vencida})';
}


}

/// @nodoc
abstract mixin class $TaskDtoCopyWith<$Res>  {
  factory $TaskDtoCopyWith(TaskDto value, $Res Function(TaskDto) _then) = _$TaskDtoCopyWithImpl;
@useResult
$Res call({
 String tipo,@JsonKey(name: 'referencia_id') int referenciaId,@JsonKey(name: 'emprendimiento_id') int emprendimientoId, String titulo, String? detalle, String? responsable, String estado,@JsonKey(name: 'fecha_prevista') DateTime? fechaPrevista, bool vencida
});




}
/// @nodoc
class _$TaskDtoCopyWithImpl<$Res>
    implements $TaskDtoCopyWith<$Res> {
  _$TaskDtoCopyWithImpl(this._self, this._then);

  final TaskDto _self;
  final $Res Function(TaskDto) _then;

/// Create a copy of TaskDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tipo = null,Object? referenciaId = null,Object? emprendimientoId = null,Object? titulo = null,Object? detalle = freezed,Object? responsable = freezed,Object? estado = null,Object? fechaPrevista = freezed,Object? vencida = null,}) {
  return _then(TaskDto(
tipo: null == tipo ? _self.tipo : tipo // ignore: cast_nullable_to_non_nullable
as String,referenciaId: null == referenciaId ? _self.referenciaId : referenciaId // ignore: cast_nullable_to_non_nullable
as int,emprendimientoId: null == emprendimientoId ? _self.emprendimientoId : emprendimientoId // ignore: cast_nullable_to_non_nullable
as int,titulo: null == titulo ? _self.titulo : titulo // ignore: cast_nullable_to_non_nullable
as String,detalle: freezed == detalle ? _self.detalle : detalle // ignore: cast_nullable_to_non_nullable
as String?,responsable: freezed == responsable ? _self.responsable : responsable // ignore: cast_nullable_to_non_nullable
as String?,estado: null == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as String,fechaPrevista: freezed == fechaPrevista ? _self.fechaPrevista : fechaPrevista // ignore: cast_nullable_to_non_nullable
as DateTime?,vencida: null == vencida ? _self.vencida : vencida // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [TaskDto].
extension TaskDtoPatterns on TaskDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TaskDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TaskDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TaskDto value)  $default,){
final _that = this;
switch (_that) {
case _TaskDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TaskDto value)?  $default,){
final _that = this;
switch (_that) {
case _TaskDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String tipo, @JsonKey(name: 'referencia_id')  int referenciaId, @JsonKey(name: 'emprendimiento_id')  int emprendimientoId,  String titulo,  String? detalle,  String? responsable,  String estado, @JsonKey(name: 'fecha_prevista')  DateTime? fechaPrevista,  bool vencida)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TaskDto() when $default != null:
return $default(_that.tipo,_that.referenciaId,_that.emprendimientoId,_that.titulo,_that.detalle,_that.responsable,_that.estado,_that.fechaPrevista,_that.vencida);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String tipo, @JsonKey(name: 'referencia_id')  int referenciaId, @JsonKey(name: 'emprendimiento_id')  int emprendimientoId,  String titulo,  String? detalle,  String? responsable,  String estado, @JsonKey(name: 'fecha_prevista')  DateTime? fechaPrevista,  bool vencida)  $default,) {final _that = this;
switch (_that) {
case _TaskDto():
return $default(_that.tipo,_that.referenciaId,_that.emprendimientoId,_that.titulo,_that.detalle,_that.responsable,_that.estado,_that.fechaPrevista,_that.vencida);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String tipo, @JsonKey(name: 'referencia_id')  int referenciaId, @JsonKey(name: 'emprendimiento_id')  int emprendimientoId,  String titulo,  String? detalle,  String? responsable,  String estado, @JsonKey(name: 'fecha_prevista')  DateTime? fechaPrevista,  bool vencida)?  $default,) {final _that = this;
switch (_that) {
case _TaskDto() when $default != null:
return $default(_that.tipo,_that.referenciaId,_that.emprendimientoId,_that.titulo,_that.detalle,_that.responsable,_that.estado,_that.fechaPrevista,_that.vencida);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TaskDto extends TaskDto {
  const _TaskDto({required this.tipo, @JsonKey(name: 'referencia_id') required this.referenciaId, @JsonKey(name: 'emprendimiento_id') required this.emprendimientoId, required this.titulo, this.detalle, this.responsable, required this.estado, @JsonKey(name: 'fecha_prevista') this.fechaPrevista, this.vencida = false}): super._();
  factory _TaskDto.fromJson(Map<String, dynamic> json) => _$TaskDtoFromJson(json);

@override final  String tipo;
@override@JsonKey(name: 'referencia_id') final  int referenciaId;
@override@JsonKey(name: 'emprendimiento_id') final  int emprendimientoId;
@override final  String titulo;
@override final  String? detalle;
@override final  String? responsable;
@override final  String estado;
@override@JsonKey(name: 'fecha_prevista') final  DateTime? fechaPrevista;
@override@JsonKey() final  bool vencida;

/// Create a copy of TaskDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskDtoCopyWith<_TaskDto> get copyWith => __$TaskDtoCopyWithImpl<_TaskDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TaskDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaskDto&&(identical(other.tipo, tipo) || other.tipo == tipo)&&(identical(other.referenciaId, referenciaId) || other.referenciaId == referenciaId)&&(identical(other.emprendimientoId, emprendimientoId) || other.emprendimientoId == emprendimientoId)&&(identical(other.titulo, titulo) || other.titulo == titulo)&&(identical(other.detalle, detalle) || other.detalle == detalle)&&(identical(other.responsable, responsable) || other.responsable == responsable)&&(identical(other.estado, estado) || other.estado == estado)&&(identical(other.fechaPrevista, fechaPrevista) || other.fechaPrevista == fechaPrevista)&&(identical(other.vencida, vencida) || other.vencida == vencida));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,tipo,referenciaId,emprendimientoId,titulo,detalle,responsable,estado,fechaPrevista,vencida);
}

@override
String toString() {
    return 'TaskDto(tipo: $tipo, referenciaId: $referenciaId, emprendimientoId: $emprendimientoId, titulo: $titulo, detalle: $detalle, responsable: $responsable, estado: $estado, fechaPrevista: $fechaPrevista, vencida: $vencida)';
}


}

/// @nodoc
abstract mixin class _$TaskDtoCopyWith<$Res> implements $TaskDtoCopyWith<$Res> {
  factory _$TaskDtoCopyWith(_TaskDto value, $Res Function(_TaskDto) _then) = __$TaskDtoCopyWithImpl;
@override @useResult
$Res call({
 String tipo,@JsonKey(name: 'referencia_id') int referenciaId,@JsonKey(name: 'emprendimiento_id') int emprendimientoId, String titulo, String? detalle, String? responsable, String estado,@JsonKey(name: 'fecha_prevista') DateTime? fechaPrevista, bool vencida
});




}
/// @nodoc
class __$TaskDtoCopyWithImpl<$Res>
    implements _$TaskDtoCopyWith<$Res> {
  __$TaskDtoCopyWithImpl(this._self, this._then);

  final _TaskDto _self;
  final $Res Function(_TaskDto) _then;

/// Create a copy of TaskDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tipo = null,Object? referenciaId = null,Object? emprendimientoId = null,Object? titulo = null,Object? detalle = freezed,Object? responsable = freezed,Object? estado = null,Object? fechaPrevista = freezed,Object? vencida = null,}) {
  return _then(_TaskDto(
tipo: null == tipo ? _self.tipo : tipo // ignore: cast_nullable_to_non_nullable
as String,referenciaId: null == referenciaId ? _self.referenciaId : referenciaId // ignore: cast_nullable_to_non_nullable
as int,emprendimientoId: null == emprendimientoId ? _self.emprendimientoId : emprendimientoId // ignore: cast_nullable_to_non_nullable
as int,titulo: null == titulo ? _self.titulo : titulo // ignore: cast_nullable_to_non_nullable
as String,detalle: freezed == detalle ? _self.detalle : detalle // ignore: cast_nullable_to_non_nullable
as String?,responsable: freezed == responsable ? _self.responsable : responsable // ignore: cast_nullable_to_non_nullable
as String?,estado: null == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as String,fechaPrevista: freezed == fechaPrevista ? _self.fechaPrevista : fechaPrevista // ignore: cast_nullable_to_non_nullable
as DateTime?,vencida: null == vencida ? _self.vencida : vencida // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
