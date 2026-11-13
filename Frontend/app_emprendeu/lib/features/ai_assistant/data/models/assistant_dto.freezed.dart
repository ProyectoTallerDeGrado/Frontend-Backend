// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'assistant_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChatMessageDto {

@JsonKey(name: 'mensaje_id') int get mensajeId; String? get tipo; String get contenido;
/// Create a copy of ChatMessageDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatMessageDtoCopyWith<ChatMessageDto> get copyWith => _$ChatMessageDtoCopyWithImpl<ChatMessageDto>(this as ChatMessageDto, _$identity);

  /// Serializes this ChatMessageDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ChatMessageDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatMessageDto&&(identical(other.mensajeId, _this.mensajeId) || other.mensajeId == _this.mensajeId)&&(identical(other.tipo, _this.tipo) || other.tipo == _this.tipo)&&(identical(other.contenido, _this.contenido) || other.contenido == _this.contenido));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ChatMessageDto;
  return Object.hash(runtimeType,_this.mensajeId,_this.tipo,_this.contenido);
}

@override
String toString() {
  final _this = this as ChatMessageDto;
  return 'ChatMessageDto(mensajeId: ${_this.mensajeId}, tipo: ${_this.tipo}, contenido: ${_this.contenido})';
}


}

/// @nodoc
abstract mixin class $ChatMessageDtoCopyWith<$Res>  {
  factory $ChatMessageDtoCopyWith(ChatMessageDto value, $Res Function(ChatMessageDto) _then) = _$ChatMessageDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'mensaje_id') int mensajeId, String? tipo, String contenido
});




}
/// @nodoc
class _$ChatMessageDtoCopyWithImpl<$Res>
    implements $ChatMessageDtoCopyWith<$Res> {
  _$ChatMessageDtoCopyWithImpl(this._self, this._then);

  final ChatMessageDto _self;
  final $Res Function(ChatMessageDto) _then;

/// Create a copy of ChatMessageDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? mensajeId = null,Object? tipo = freezed,Object? contenido = null,}) {
  return _then(ChatMessageDto(
mensajeId: null == mensajeId ? _self.mensajeId : mensajeId // ignore: cast_nullable_to_non_nullable
as int,tipo: freezed == tipo ? _self.tipo : tipo // ignore: cast_nullable_to_non_nullable
as String?,contenido: null == contenido ? _self.contenido : contenido // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatMessageDto].
extension ChatMessageDtoPatterns on ChatMessageDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatMessageDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatMessageDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatMessageDto value)  $default,){
final _that = this;
switch (_that) {
case _ChatMessageDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatMessageDto value)?  $default,){
final _that = this;
switch (_that) {
case _ChatMessageDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'mensaje_id')  int mensajeId,  String? tipo,  String contenido)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatMessageDto() when $default != null:
return $default(_that.mensajeId,_that.tipo,_that.contenido);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'mensaje_id')  int mensajeId,  String? tipo,  String contenido)  $default,) {final _that = this;
switch (_that) {
case _ChatMessageDto():
return $default(_that.mensajeId,_that.tipo,_that.contenido);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'mensaje_id')  int mensajeId,  String? tipo,  String contenido)?  $default,) {final _that = this;
switch (_that) {
case _ChatMessageDto() when $default != null:
return $default(_that.mensajeId,_that.tipo,_that.contenido);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChatMessageDto extends ChatMessageDto {
  const _ChatMessageDto({@JsonKey(name: 'mensaje_id') required this.mensajeId, this.tipo, required this.contenido}): super._();
  factory _ChatMessageDto.fromJson(Map<String, dynamic> json) => _$ChatMessageDtoFromJson(json);

@override@JsonKey(name: 'mensaje_id') final  int mensajeId;
@override final  String? tipo;
@override final  String contenido;

/// Create a copy of ChatMessageDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatMessageDtoCopyWith<_ChatMessageDto> get copyWith => __$ChatMessageDtoCopyWithImpl<_ChatMessageDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatMessageDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatMessageDto&&(identical(other.mensajeId, mensajeId) || other.mensajeId == mensajeId)&&(identical(other.tipo, tipo) || other.tipo == tipo)&&(identical(other.contenido, contenido) || other.contenido == contenido));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,mensajeId,tipo,contenido);
}

@override
String toString() {
    return 'ChatMessageDto(mensajeId: $mensajeId, tipo: $tipo, contenido: $contenido)';
}


}

/// @nodoc
abstract mixin class _$ChatMessageDtoCopyWith<$Res> implements $ChatMessageDtoCopyWith<$Res> {
  factory _$ChatMessageDtoCopyWith(_ChatMessageDto value, $Res Function(_ChatMessageDto) _then) = __$ChatMessageDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'mensaje_id') int mensajeId, String? tipo, String contenido
});




}
/// @nodoc
class __$ChatMessageDtoCopyWithImpl<$Res>
    implements _$ChatMessageDtoCopyWith<$Res> {
  __$ChatMessageDtoCopyWithImpl(this._self, this._then);

  final _ChatMessageDto _self;
  final $Res Function(_ChatMessageDto) _then;

/// Create a copy of ChatMessageDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? mensajeId = null,Object? tipo = freezed,Object? contenido = null,}) {
  return _then(_ChatMessageDto(
mensajeId: null == mensajeId ? _self.mensajeId : mensajeId // ignore: cast_nullable_to_non_nullable
as int,tipo: freezed == tipo ? _self.tipo : tipo // ignore: cast_nullable_to_non_nullable
as String?,contenido: null == contenido ? _self.contenido : contenido // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ConversationSummaryDto {

@JsonKey(name: 'conversacion_id') int get conversacionId;@JsonKey(name: 'total_mensajes') int get totalMensajes;@JsonKey(name: 'fecha_inicio') DateTime? get fechaInicio;@JsonKey(name: 'fecha_fin') DateTime? get fechaFin;
/// Create a copy of ConversationSummaryDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConversationSummaryDtoCopyWith<ConversationSummaryDto> get copyWith => _$ConversationSummaryDtoCopyWithImpl<ConversationSummaryDto>(this as ConversationSummaryDto, _$identity);

  /// Serializes this ConversationSummaryDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ConversationSummaryDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConversationSummaryDto&&(identical(other.conversacionId, _this.conversacionId) || other.conversacionId == _this.conversacionId)&&(identical(other.totalMensajes, _this.totalMensajes) || other.totalMensajes == _this.totalMensajes)&&(identical(other.fechaInicio, _this.fechaInicio) || other.fechaInicio == _this.fechaInicio)&&(identical(other.fechaFin, _this.fechaFin) || other.fechaFin == _this.fechaFin));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ConversationSummaryDto;
  return Object.hash(runtimeType,_this.conversacionId,_this.totalMensajes,_this.fechaInicio,_this.fechaFin);
}

@override
String toString() {
  final _this = this as ConversationSummaryDto;
  return 'ConversationSummaryDto(conversacionId: ${_this.conversacionId}, totalMensajes: ${_this.totalMensajes}, fechaInicio: ${_this.fechaInicio}, fechaFin: ${_this.fechaFin})';
}


}

/// @nodoc
abstract mixin class $ConversationSummaryDtoCopyWith<$Res>  {
  factory $ConversationSummaryDtoCopyWith(ConversationSummaryDto value, $Res Function(ConversationSummaryDto) _then) = _$ConversationSummaryDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'conversacion_id') int conversacionId,@JsonKey(name: 'total_mensajes') int totalMensajes,@JsonKey(name: 'fecha_inicio') DateTime? fechaInicio,@JsonKey(name: 'fecha_fin') DateTime? fechaFin
});




}
/// @nodoc
class _$ConversationSummaryDtoCopyWithImpl<$Res>
    implements $ConversationSummaryDtoCopyWith<$Res> {
  _$ConversationSummaryDtoCopyWithImpl(this._self, this._then);

  final ConversationSummaryDto _self;
  final $Res Function(ConversationSummaryDto) _then;

/// Create a copy of ConversationSummaryDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? conversacionId = null,Object? totalMensajes = null,Object? fechaInicio = freezed,Object? fechaFin = freezed,}) {
  return _then(ConversationSummaryDto(
conversacionId: null == conversacionId ? _self.conversacionId : conversacionId // ignore: cast_nullable_to_non_nullable
as int,totalMensajes: null == totalMensajes ? _self.totalMensajes : totalMensajes // ignore: cast_nullable_to_non_nullable
as int,fechaInicio: freezed == fechaInicio ? _self.fechaInicio : fechaInicio // ignore: cast_nullable_to_non_nullable
as DateTime?,fechaFin: freezed == fechaFin ? _self.fechaFin : fechaFin // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ConversationSummaryDto].
extension ConversationSummaryDtoPatterns on ConversationSummaryDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConversationSummaryDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConversationSummaryDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConversationSummaryDto value)  $default,){
final _that = this;
switch (_that) {
case _ConversationSummaryDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConversationSummaryDto value)?  $default,){
final _that = this;
switch (_that) {
case _ConversationSummaryDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'conversacion_id')  int conversacionId, @JsonKey(name: 'total_mensajes')  int totalMensajes, @JsonKey(name: 'fecha_inicio')  DateTime? fechaInicio, @JsonKey(name: 'fecha_fin')  DateTime? fechaFin)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConversationSummaryDto() when $default != null:
return $default(_that.conversacionId,_that.totalMensajes,_that.fechaInicio,_that.fechaFin);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'conversacion_id')  int conversacionId, @JsonKey(name: 'total_mensajes')  int totalMensajes, @JsonKey(name: 'fecha_inicio')  DateTime? fechaInicio, @JsonKey(name: 'fecha_fin')  DateTime? fechaFin)  $default,) {final _that = this;
switch (_that) {
case _ConversationSummaryDto():
return $default(_that.conversacionId,_that.totalMensajes,_that.fechaInicio,_that.fechaFin);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'conversacion_id')  int conversacionId, @JsonKey(name: 'total_mensajes')  int totalMensajes, @JsonKey(name: 'fecha_inicio')  DateTime? fechaInicio, @JsonKey(name: 'fecha_fin')  DateTime? fechaFin)?  $default,) {final _that = this;
switch (_that) {
case _ConversationSummaryDto() when $default != null:
return $default(_that.conversacionId,_that.totalMensajes,_that.fechaInicio,_that.fechaFin);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ConversationSummaryDto extends ConversationSummaryDto {
  const _ConversationSummaryDto({@JsonKey(name: 'conversacion_id') required this.conversacionId, @JsonKey(name: 'total_mensajes') this.totalMensajes = 0, @JsonKey(name: 'fecha_inicio') this.fechaInicio, @JsonKey(name: 'fecha_fin') this.fechaFin}): super._();
  factory _ConversationSummaryDto.fromJson(Map<String, dynamic> json) => _$ConversationSummaryDtoFromJson(json);

@override@JsonKey(name: 'conversacion_id') final  int conversacionId;
@override@JsonKey(name: 'total_mensajes') final  int totalMensajes;
@override@JsonKey(name: 'fecha_inicio') final  DateTime? fechaInicio;
@override@JsonKey(name: 'fecha_fin') final  DateTime? fechaFin;

/// Create a copy of ConversationSummaryDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConversationSummaryDtoCopyWith<_ConversationSummaryDto> get copyWith => __$ConversationSummaryDtoCopyWithImpl<_ConversationSummaryDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ConversationSummaryDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConversationSummaryDto&&(identical(other.conversacionId, conversacionId) || other.conversacionId == conversacionId)&&(identical(other.totalMensajes, totalMensajes) || other.totalMensajes == totalMensajes)&&(identical(other.fechaInicio, fechaInicio) || other.fechaInicio == fechaInicio)&&(identical(other.fechaFin, fechaFin) || other.fechaFin == fechaFin));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,conversacionId,totalMensajes,fechaInicio,fechaFin);
}

@override
String toString() {
    return 'ConversationSummaryDto(conversacionId: $conversacionId, totalMensajes: $totalMensajes, fechaInicio: $fechaInicio, fechaFin: $fechaFin)';
}


}

/// @nodoc
abstract mixin class _$ConversationSummaryDtoCopyWith<$Res> implements $ConversationSummaryDtoCopyWith<$Res> {
  factory _$ConversationSummaryDtoCopyWith(_ConversationSummaryDto value, $Res Function(_ConversationSummaryDto) _then) = __$ConversationSummaryDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'conversacion_id') int conversacionId,@JsonKey(name: 'total_mensajes') int totalMensajes,@JsonKey(name: 'fecha_inicio') DateTime? fechaInicio,@JsonKey(name: 'fecha_fin') DateTime? fechaFin
});




}
/// @nodoc
class __$ConversationSummaryDtoCopyWithImpl<$Res>
    implements _$ConversationSummaryDtoCopyWith<$Res> {
  __$ConversationSummaryDtoCopyWithImpl(this._self, this._then);

  final _ConversationSummaryDto _self;
  final $Res Function(_ConversationSummaryDto) _then;

/// Create a copy of ConversationSummaryDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? conversacionId = null,Object? totalMensajes = null,Object? fechaInicio = freezed,Object? fechaFin = freezed,}) {
  return _then(_ConversationSummaryDto(
conversacionId: null == conversacionId ? _self.conversacionId : conversacionId // ignore: cast_nullable_to_non_nullable
as int,totalMensajes: null == totalMensajes ? _self.totalMensajes : totalMensajes // ignore: cast_nullable_to_non_nullable
as int,fechaInicio: freezed == fechaInicio ? _self.fechaInicio : fechaInicio // ignore: cast_nullable_to_non_nullable
as DateTime?,fechaFin: freezed == fechaFin ? _self.fechaFin : fechaFin // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$ChatReplyDto {

@JsonKey(name: 'conversacion_id') int get conversacionId; ChatMessageDto get pregunta; ChatMessageDto get respuesta; List<String> get fuentes;@JsonKey(name: 'derivar_mentor') bool get derivarMentor;
/// Create a copy of ChatReplyDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatReplyDtoCopyWith<ChatReplyDto> get copyWith => _$ChatReplyDtoCopyWithImpl<ChatReplyDto>(this as ChatReplyDto, _$identity);

  /// Serializes this ChatReplyDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ChatReplyDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatReplyDto&&(identical(other.conversacionId, _this.conversacionId) || other.conversacionId == _this.conversacionId)&&(identical(other.pregunta, _this.pregunta) || other.pregunta == _this.pregunta)&&(identical(other.respuesta, _this.respuesta) || other.respuesta == _this.respuesta)&&const DeepCollectionEquality().equals(other.fuentes, _this.fuentes)&&(identical(other.derivarMentor, _this.derivarMentor) || other.derivarMentor == _this.derivarMentor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ChatReplyDto;
  return Object.hash(runtimeType,_this.conversacionId,_this.pregunta,_this.respuesta,const DeepCollectionEquality().hash(_this.fuentes),_this.derivarMentor);
}

@override
String toString() {
  final _this = this as ChatReplyDto;
  return 'ChatReplyDto(conversacionId: ${_this.conversacionId}, pregunta: ${_this.pregunta}, respuesta: ${_this.respuesta}, fuentes: ${_this.fuentes}, derivarMentor: ${_this.derivarMentor})';
}


}

/// @nodoc
abstract mixin class $ChatReplyDtoCopyWith<$Res>  {
  factory $ChatReplyDtoCopyWith(ChatReplyDto value, $Res Function(ChatReplyDto) _then) = _$ChatReplyDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'conversacion_id') int conversacionId, ChatMessageDto pregunta, ChatMessageDto respuesta, List<String> fuentes,@JsonKey(name: 'derivar_mentor') bool derivarMentor
});


$ChatMessageDtoCopyWith<$Res> get pregunta;$ChatMessageDtoCopyWith<$Res> get respuesta;

}
/// @nodoc
class _$ChatReplyDtoCopyWithImpl<$Res>
    implements $ChatReplyDtoCopyWith<$Res> {
  _$ChatReplyDtoCopyWithImpl(this._self, this._then);

  final ChatReplyDto _self;
  final $Res Function(ChatReplyDto) _then;

/// Create a copy of ChatReplyDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? conversacionId = null,Object? pregunta = null,Object? respuesta = null,Object? fuentes = null,Object? derivarMentor = null,}) {
  return _then(ChatReplyDto(
conversacionId: null == conversacionId ? _self.conversacionId : conversacionId // ignore: cast_nullable_to_non_nullable
as int,pregunta: null == pregunta ? _self.pregunta : pregunta // ignore: cast_nullable_to_non_nullable
as ChatMessageDto,respuesta: null == respuesta ? _self.respuesta : respuesta // ignore: cast_nullable_to_non_nullable
as ChatMessageDto,fuentes: null == fuentes ? _self.fuentes : fuentes // ignore: cast_nullable_to_non_nullable
as List<String>,derivarMentor: null == derivarMentor ? _self.derivarMentor : derivarMentor // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of ChatReplyDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatMessageDtoCopyWith<$Res> get pregunta {
  
  return $ChatMessageDtoCopyWith<$Res>(_self.pregunta, (value) {
    return _then(_self.copyWith(pregunta: value));
  });
}/// Create a copy of ChatReplyDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatMessageDtoCopyWith<$Res> get respuesta {
  
  return $ChatMessageDtoCopyWith<$Res>(_self.respuesta, (value) {
    return _then(_self.copyWith(respuesta: value));
  });
}
}


/// Adds pattern-matching-related methods to [ChatReplyDto].
extension ChatReplyDtoPatterns on ChatReplyDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatReplyDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatReplyDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatReplyDto value)  $default,){
final _that = this;
switch (_that) {
case _ChatReplyDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatReplyDto value)?  $default,){
final _that = this;
switch (_that) {
case _ChatReplyDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'conversacion_id')  int conversacionId,  ChatMessageDto pregunta,  ChatMessageDto respuesta,  List<String> fuentes, @JsonKey(name: 'derivar_mentor')  bool derivarMentor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatReplyDto() when $default != null:
return $default(_that.conversacionId,_that.pregunta,_that.respuesta,_that.fuentes,_that.derivarMentor);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'conversacion_id')  int conversacionId,  ChatMessageDto pregunta,  ChatMessageDto respuesta,  List<String> fuentes, @JsonKey(name: 'derivar_mentor')  bool derivarMentor)  $default,) {final _that = this;
switch (_that) {
case _ChatReplyDto():
return $default(_that.conversacionId,_that.pregunta,_that.respuesta,_that.fuentes,_that.derivarMentor);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'conversacion_id')  int conversacionId,  ChatMessageDto pregunta,  ChatMessageDto respuesta,  List<String> fuentes, @JsonKey(name: 'derivar_mentor')  bool derivarMentor)?  $default,) {final _that = this;
switch (_that) {
case _ChatReplyDto() when $default != null:
return $default(_that.conversacionId,_that.pregunta,_that.respuesta,_that.fuentes,_that.derivarMentor);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChatReplyDto extends ChatReplyDto {
  const _ChatReplyDto({@JsonKey(name: 'conversacion_id') required this.conversacionId, required this.pregunta, required this.respuesta,  List<String> fuentes = const <String>[], @JsonKey(name: 'derivar_mentor') this.derivarMentor = false}): _fuentes = fuentes,super._();
  factory _ChatReplyDto.fromJson(Map<String, dynamic> json) => _$ChatReplyDtoFromJson(json);

@override@JsonKey(name: 'conversacion_id') final  int conversacionId;
@override final  ChatMessageDto pregunta;
@override final  ChatMessageDto respuesta;
 final  List<String> _fuentes;
@override@JsonKey() List<String> get fuentes {
  if (_fuentes is EqualUnmodifiableListView) return _fuentes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_fuentes);
}

@override@JsonKey(name: 'derivar_mentor') final  bool derivarMentor;

/// Create a copy of ChatReplyDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatReplyDtoCopyWith<_ChatReplyDto> get copyWith => __$ChatReplyDtoCopyWithImpl<_ChatReplyDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatReplyDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatReplyDto&&(identical(other.conversacionId, conversacionId) || other.conversacionId == conversacionId)&&(identical(other.pregunta, pregunta) || other.pregunta == pregunta)&&(identical(other.respuesta, respuesta) || other.respuesta == respuesta)&&const DeepCollectionEquality().equals(other.fuentes, _fuentes)&&(identical(other.derivarMentor, derivarMentor) || other.derivarMentor == derivarMentor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,conversacionId,pregunta,respuesta,const DeepCollectionEquality().hash(_fuentes),derivarMentor);
}

@override
String toString() {
    return 'ChatReplyDto(conversacionId: $conversacionId, pregunta: $pregunta, respuesta: $respuesta, fuentes: $fuentes, derivarMentor: $derivarMentor)';
}


}

/// @nodoc
abstract mixin class _$ChatReplyDtoCopyWith<$Res> implements $ChatReplyDtoCopyWith<$Res> {
  factory _$ChatReplyDtoCopyWith(_ChatReplyDto value, $Res Function(_ChatReplyDto) _then) = __$ChatReplyDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'conversacion_id') int conversacionId, ChatMessageDto pregunta, ChatMessageDto respuesta, List<String> fuentes,@JsonKey(name: 'derivar_mentor') bool derivarMentor
});


@override $ChatMessageDtoCopyWith<$Res> get pregunta;@override $ChatMessageDtoCopyWith<$Res> get respuesta;

}
/// @nodoc
class __$ChatReplyDtoCopyWithImpl<$Res>
    implements _$ChatReplyDtoCopyWith<$Res> {
  __$ChatReplyDtoCopyWithImpl(this._self, this._then);

  final _ChatReplyDto _self;
  final $Res Function(_ChatReplyDto) _then;

/// Create a copy of ChatReplyDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? conversacionId = null,Object? pregunta = null,Object? respuesta = null,Object? fuentes = null,Object? derivarMentor = null,}) {
  return _then(_ChatReplyDto(
conversacionId: null == conversacionId ? _self.conversacionId : conversacionId // ignore: cast_nullable_to_non_nullable
as int,pregunta: null == pregunta ? _self.pregunta : pregunta // ignore: cast_nullable_to_non_nullable
as ChatMessageDto,respuesta: null == respuesta ? _self.respuesta : respuesta // ignore: cast_nullable_to_non_nullable
as ChatMessageDto,fuentes: null == fuentes ? _self._fuentes : fuentes // ignore: cast_nullable_to_non_nullable
as List<String>,derivarMentor: null == derivarMentor ? _self.derivarMentor : derivarMentor // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of ChatReplyDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatMessageDtoCopyWith<$Res> get pregunta {
  
  return $ChatMessageDtoCopyWith<$Res>(_self.pregunta, (value) {
    return _then(_self.copyWith(pregunta: value));
  });
}/// Create a copy of ChatReplyDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatMessageDtoCopyWith<$Res> get respuesta {
  
  return $ChatMessageDtoCopyWith<$Res>(_self.respuesta, (value) {
    return _then(_self.copyWith(respuesta: value));
  });
}
}

// dart format on
