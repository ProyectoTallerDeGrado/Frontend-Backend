// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'knowledge_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$KnowledgeIndexDto {

@JsonKey(name: 'modelo_embeddings') String get modeloEmbeddings; int get dimension; List<IndexDocumentDto> get documentos;
/// Create a copy of KnowledgeIndexDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$KnowledgeIndexDtoCopyWith<KnowledgeIndexDto> get copyWith => _$KnowledgeIndexDtoCopyWithImpl<KnowledgeIndexDto>(this as KnowledgeIndexDto, _$identity);

  /// Serializes this KnowledgeIndexDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as KnowledgeIndexDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is KnowledgeIndexDto&&(identical(other.modeloEmbeddings, _this.modeloEmbeddings) || other.modeloEmbeddings == _this.modeloEmbeddings)&&(identical(other.dimension, _this.dimension) || other.dimension == _this.dimension)&&const DeepCollectionEquality().equals(other.documentos, _this.documentos));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as KnowledgeIndexDto;
  return Object.hash(runtimeType,_this.modeloEmbeddings,_this.dimension,const DeepCollectionEquality().hash(_this.documentos));
}

@override
String toString() {
  final _this = this as KnowledgeIndexDto;
  return 'KnowledgeIndexDto(modeloEmbeddings: ${_this.modeloEmbeddings}, dimension: ${_this.dimension}, documentos: ${_this.documentos})';
}


}

/// @nodoc
abstract mixin class $KnowledgeIndexDtoCopyWith<$Res>  {
  factory $KnowledgeIndexDtoCopyWith(KnowledgeIndexDto value, $Res Function(KnowledgeIndexDto) _then) = _$KnowledgeIndexDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'modelo_embeddings') String modeloEmbeddings, int dimension, List<IndexDocumentDto> documentos
});




}
/// @nodoc
class _$KnowledgeIndexDtoCopyWithImpl<$Res>
    implements $KnowledgeIndexDtoCopyWith<$Res> {
  _$KnowledgeIndexDtoCopyWithImpl(this._self, this._then);

  final KnowledgeIndexDto _self;
  final $Res Function(KnowledgeIndexDto) _then;

/// Create a copy of KnowledgeIndexDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? modeloEmbeddings = null,Object? dimension = null,Object? documentos = null,}) {
  return _then(KnowledgeIndexDto(
modeloEmbeddings: null == modeloEmbeddings ? _self.modeloEmbeddings : modeloEmbeddings // ignore: cast_nullable_to_non_nullable
as String,dimension: null == dimension ? _self.dimension : dimension // ignore: cast_nullable_to_non_nullable
as int,documentos: null == documentos ? _self.documentos : documentos // ignore: cast_nullable_to_non_nullable
as List<IndexDocumentDto>,
  ));
}

}


/// Adds pattern-matching-related methods to [KnowledgeIndexDto].
extension KnowledgeIndexDtoPatterns on KnowledgeIndexDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _KnowledgeIndexDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _KnowledgeIndexDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _KnowledgeIndexDto value)  $default,){
final _that = this;
switch (_that) {
case _KnowledgeIndexDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _KnowledgeIndexDto value)?  $default,){
final _that = this;
switch (_that) {
case _KnowledgeIndexDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'modelo_embeddings')  String modeloEmbeddings,  int dimension,  List<IndexDocumentDto> documentos)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _KnowledgeIndexDto() when $default != null:
return $default(_that.modeloEmbeddings,_that.dimension,_that.documentos);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'modelo_embeddings')  String modeloEmbeddings,  int dimension,  List<IndexDocumentDto> documentos)  $default,) {final _that = this;
switch (_that) {
case _KnowledgeIndexDto():
return $default(_that.modeloEmbeddings,_that.dimension,_that.documentos);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'modelo_embeddings')  String modeloEmbeddings,  int dimension,  List<IndexDocumentDto> documentos)?  $default,) {final _that = this;
switch (_that) {
case _KnowledgeIndexDto() when $default != null:
return $default(_that.modeloEmbeddings,_that.dimension,_that.documentos);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _KnowledgeIndexDto implements KnowledgeIndexDto {
  const _KnowledgeIndexDto({@JsonKey(name: 'modelo_embeddings') required this.modeloEmbeddings, required this.dimension,  List<IndexDocumentDto> documentos = const <IndexDocumentDto>[]}): _documentos = documentos;
  factory _KnowledgeIndexDto.fromJson(Map<String, dynamic> json) => _$KnowledgeIndexDtoFromJson(json);

@override@JsonKey(name: 'modelo_embeddings') final  String modeloEmbeddings;
@override final  int dimension;
 final  List<IndexDocumentDto> _documentos;
@override@JsonKey() List<IndexDocumentDto> get documentos {
  if (_documentos is EqualUnmodifiableListView) return _documentos;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_documentos);
}


/// Create a copy of KnowledgeIndexDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$KnowledgeIndexDtoCopyWith<_KnowledgeIndexDto> get copyWith => __$KnowledgeIndexDtoCopyWithImpl<_KnowledgeIndexDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$KnowledgeIndexDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _KnowledgeIndexDto&&(identical(other.modeloEmbeddings, modeloEmbeddings) || other.modeloEmbeddings == modeloEmbeddings)&&(identical(other.dimension, dimension) || other.dimension == dimension)&&const DeepCollectionEquality().equals(other.documentos, _documentos));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,modeloEmbeddings,dimension,const DeepCollectionEquality().hash(_documentos));
}

@override
String toString() {
    return 'KnowledgeIndexDto(modeloEmbeddings: $modeloEmbeddings, dimension: $dimension, documentos: $documentos)';
}


}

/// @nodoc
abstract mixin class _$KnowledgeIndexDtoCopyWith<$Res> implements $KnowledgeIndexDtoCopyWith<$Res> {
  factory _$KnowledgeIndexDtoCopyWith(_KnowledgeIndexDto value, $Res Function(_KnowledgeIndexDto) _then) = __$KnowledgeIndexDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'modelo_embeddings') String modeloEmbeddings, int dimension, List<IndexDocumentDto> documentos
});




}
/// @nodoc
class __$KnowledgeIndexDtoCopyWithImpl<$Res>
    implements _$KnowledgeIndexDtoCopyWith<$Res> {
  __$KnowledgeIndexDtoCopyWithImpl(this._self, this._then);

  final _KnowledgeIndexDto _self;
  final $Res Function(_KnowledgeIndexDto) _then;

/// Create a copy of KnowledgeIndexDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? modeloEmbeddings = null,Object? dimension = null,Object? documentos = null,}) {
  return _then(_KnowledgeIndexDto(
modeloEmbeddings: null == modeloEmbeddings ? _self.modeloEmbeddings : modeloEmbeddings // ignore: cast_nullable_to_non_nullable
as String,dimension: null == dimension ? _self.dimension : dimension // ignore: cast_nullable_to_non_nullable
as int,documentos: null == documentos ? _self._documentos : documentos // ignore: cast_nullable_to_non_nullable
as List<IndexDocumentDto>,
  ));
}


}


/// @nodoc
mixin _$IndexDocumentDto {

@JsonKey(name: 'documento_conocimiento_id') int get id; String get titulo; String? get fuente;@JsonKey(name: 'fecha_carga') DateTime? get fechaCarga;@JsonKey(name: 'total_fragmentos') int get totalFragmentos;
/// Create a copy of IndexDocumentDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IndexDocumentDtoCopyWith<IndexDocumentDto> get copyWith => _$IndexDocumentDtoCopyWithImpl<IndexDocumentDto>(this as IndexDocumentDto, _$identity);

  /// Serializes this IndexDocumentDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as IndexDocumentDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IndexDocumentDto&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.titulo, _this.titulo) || other.titulo == _this.titulo)&&(identical(other.fuente, _this.fuente) || other.fuente == _this.fuente)&&(identical(other.fechaCarga, _this.fechaCarga) || other.fechaCarga == _this.fechaCarga)&&(identical(other.totalFragmentos, _this.totalFragmentos) || other.totalFragmentos == _this.totalFragmentos));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as IndexDocumentDto;
  return Object.hash(runtimeType,_this.id,_this.titulo,_this.fuente,_this.fechaCarga,_this.totalFragmentos);
}

@override
String toString() {
  final _this = this as IndexDocumentDto;
  return 'IndexDocumentDto(id: ${_this.id}, titulo: ${_this.titulo}, fuente: ${_this.fuente}, fechaCarga: ${_this.fechaCarga}, totalFragmentos: ${_this.totalFragmentos})';
}


}

/// @nodoc
abstract mixin class $IndexDocumentDtoCopyWith<$Res>  {
  factory $IndexDocumentDtoCopyWith(IndexDocumentDto value, $Res Function(IndexDocumentDto) _then) = _$IndexDocumentDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'documento_conocimiento_id') int id, String titulo, String? fuente,@JsonKey(name: 'fecha_carga') DateTime? fechaCarga,@JsonKey(name: 'total_fragmentos') int totalFragmentos
});




}
/// @nodoc
class _$IndexDocumentDtoCopyWithImpl<$Res>
    implements $IndexDocumentDtoCopyWith<$Res> {
  _$IndexDocumentDtoCopyWithImpl(this._self, this._then);

  final IndexDocumentDto _self;
  final $Res Function(IndexDocumentDto) _then;

/// Create a copy of IndexDocumentDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? titulo = null,Object? fuente = freezed,Object? fechaCarga = freezed,Object? totalFragmentos = null,}) {
  return _then(IndexDocumentDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,titulo: null == titulo ? _self.titulo : titulo // ignore: cast_nullable_to_non_nullable
as String,fuente: freezed == fuente ? _self.fuente : fuente // ignore: cast_nullable_to_non_nullable
as String?,fechaCarga: freezed == fechaCarga ? _self.fechaCarga : fechaCarga // ignore: cast_nullable_to_non_nullable
as DateTime?,totalFragmentos: null == totalFragmentos ? _self.totalFragmentos : totalFragmentos // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [IndexDocumentDto].
extension IndexDocumentDtoPatterns on IndexDocumentDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IndexDocumentDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IndexDocumentDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IndexDocumentDto value)  $default,){
final _that = this;
switch (_that) {
case _IndexDocumentDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IndexDocumentDto value)?  $default,){
final _that = this;
switch (_that) {
case _IndexDocumentDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'documento_conocimiento_id')  int id,  String titulo,  String? fuente, @JsonKey(name: 'fecha_carga')  DateTime? fechaCarga, @JsonKey(name: 'total_fragmentos')  int totalFragmentos)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IndexDocumentDto() when $default != null:
return $default(_that.id,_that.titulo,_that.fuente,_that.fechaCarga,_that.totalFragmentos);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'documento_conocimiento_id')  int id,  String titulo,  String? fuente, @JsonKey(name: 'fecha_carga')  DateTime? fechaCarga, @JsonKey(name: 'total_fragmentos')  int totalFragmentos)  $default,) {final _that = this;
switch (_that) {
case _IndexDocumentDto():
return $default(_that.id,_that.titulo,_that.fuente,_that.fechaCarga,_that.totalFragmentos);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'documento_conocimiento_id')  int id,  String titulo,  String? fuente, @JsonKey(name: 'fecha_carga')  DateTime? fechaCarga, @JsonKey(name: 'total_fragmentos')  int totalFragmentos)?  $default,) {final _that = this;
switch (_that) {
case _IndexDocumentDto() when $default != null:
return $default(_that.id,_that.titulo,_that.fuente,_that.fechaCarga,_that.totalFragmentos);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _IndexDocumentDto implements IndexDocumentDto {
  const _IndexDocumentDto({@JsonKey(name: 'documento_conocimiento_id') required this.id, required this.titulo, this.fuente, @JsonKey(name: 'fecha_carga') this.fechaCarga, @JsonKey(name: 'total_fragmentos') required this.totalFragmentos});
  factory _IndexDocumentDto.fromJson(Map<String, dynamic> json) => _$IndexDocumentDtoFromJson(json);

@override@JsonKey(name: 'documento_conocimiento_id') final  int id;
@override final  String titulo;
@override final  String? fuente;
@override@JsonKey(name: 'fecha_carga') final  DateTime? fechaCarga;
@override@JsonKey(name: 'total_fragmentos') final  int totalFragmentos;

/// Create a copy of IndexDocumentDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IndexDocumentDtoCopyWith<_IndexDocumentDto> get copyWith => __$IndexDocumentDtoCopyWithImpl<_IndexDocumentDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IndexDocumentDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _IndexDocumentDto&&(identical(other.id, id) || other.id == id)&&(identical(other.titulo, titulo) || other.titulo == titulo)&&(identical(other.fuente, fuente) || other.fuente == fuente)&&(identical(other.fechaCarga, fechaCarga) || other.fechaCarga == fechaCarga)&&(identical(other.totalFragmentos, totalFragmentos) || other.totalFragmentos == totalFragmentos));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,titulo,fuente,fechaCarga,totalFragmentos);
}

@override
String toString() {
    return 'IndexDocumentDto(id: $id, titulo: $titulo, fuente: $fuente, fechaCarga: $fechaCarga, totalFragmentos: $totalFragmentos)';
}


}

/// @nodoc
abstract mixin class _$IndexDocumentDtoCopyWith<$Res> implements $IndexDocumentDtoCopyWith<$Res> {
  factory _$IndexDocumentDtoCopyWith(_IndexDocumentDto value, $Res Function(_IndexDocumentDto) _then) = __$IndexDocumentDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'documento_conocimiento_id') int id, String titulo, String? fuente,@JsonKey(name: 'fecha_carga') DateTime? fechaCarga,@JsonKey(name: 'total_fragmentos') int totalFragmentos
});




}
/// @nodoc
class __$IndexDocumentDtoCopyWithImpl<$Res>
    implements _$IndexDocumentDtoCopyWith<$Res> {
  __$IndexDocumentDtoCopyWithImpl(this._self, this._then);

  final _IndexDocumentDto _self;
  final $Res Function(_IndexDocumentDto) _then;

/// Create a copy of IndexDocumentDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? titulo = null,Object? fuente = freezed,Object? fechaCarga = freezed,Object? totalFragmentos = null,}) {
  return _then(_IndexDocumentDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,titulo: null == titulo ? _self.titulo : titulo // ignore: cast_nullable_to_non_nullable
as String,fuente: freezed == fuente ? _self.fuente : fuente // ignore: cast_nullable_to_non_nullable
as String?,fechaCarga: freezed == fechaCarga ? _self.fechaCarga : fechaCarga // ignore: cast_nullable_to_non_nullable
as DateTime?,totalFragmentos: null == totalFragmentos ? _self.totalFragmentos : totalFragmentos // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$FragmentDto {

@JsonKey(name: 'numero_fragmento') int? get numeroFragmento; String get contenido;
/// Create a copy of FragmentDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FragmentDtoCopyWith<FragmentDto> get copyWith => _$FragmentDtoCopyWithImpl<FragmentDto>(this as FragmentDto, _$identity);

  /// Serializes this FragmentDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as FragmentDto;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FragmentDto&&(identical(other.numeroFragmento, _this.numeroFragmento) || other.numeroFragmento == _this.numeroFragmento)&&(identical(other.contenido, _this.contenido) || other.contenido == _this.contenido));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as FragmentDto;
  return Object.hash(runtimeType,_this.numeroFragmento,_this.contenido);
}

@override
String toString() {
  final _this = this as FragmentDto;
  return 'FragmentDto(numeroFragmento: ${_this.numeroFragmento}, contenido: ${_this.contenido})';
}


}

/// @nodoc
abstract mixin class $FragmentDtoCopyWith<$Res>  {
  factory $FragmentDtoCopyWith(FragmentDto value, $Res Function(FragmentDto) _then) = _$FragmentDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'numero_fragmento') int? numeroFragmento, String contenido
});




}
/// @nodoc
class _$FragmentDtoCopyWithImpl<$Res>
    implements $FragmentDtoCopyWith<$Res> {
  _$FragmentDtoCopyWithImpl(this._self, this._then);

  final FragmentDto _self;
  final $Res Function(FragmentDto) _then;

/// Create a copy of FragmentDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? numeroFragmento = freezed,Object? contenido = null,}) {
  return _then(FragmentDto(
numeroFragmento: freezed == numeroFragmento ? _self.numeroFragmento : numeroFragmento // ignore: cast_nullable_to_non_nullable
as int?,contenido: null == contenido ? _self.contenido : contenido // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [FragmentDto].
extension FragmentDtoPatterns on FragmentDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FragmentDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FragmentDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FragmentDto value)  $default,){
final _that = this;
switch (_that) {
case _FragmentDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FragmentDto value)?  $default,){
final _that = this;
switch (_that) {
case _FragmentDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'numero_fragmento')  int? numeroFragmento,  String contenido)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FragmentDto() when $default != null:
return $default(_that.numeroFragmento,_that.contenido);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'numero_fragmento')  int? numeroFragmento,  String contenido)  $default,) {final _that = this;
switch (_that) {
case _FragmentDto():
return $default(_that.numeroFragmento,_that.contenido);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'numero_fragmento')  int? numeroFragmento,  String contenido)?  $default,) {final _that = this;
switch (_that) {
case _FragmentDto() when $default != null:
return $default(_that.numeroFragmento,_that.contenido);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FragmentDto implements FragmentDto {
  const _FragmentDto({@JsonKey(name: 'numero_fragmento') this.numeroFragmento, required this.contenido});
  factory _FragmentDto.fromJson(Map<String, dynamic> json) => _$FragmentDtoFromJson(json);

@override@JsonKey(name: 'numero_fragmento') final  int? numeroFragmento;
@override final  String contenido;

/// Create a copy of FragmentDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FragmentDtoCopyWith<_FragmentDto> get copyWith => __$FragmentDtoCopyWithImpl<_FragmentDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FragmentDtoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FragmentDto&&(identical(other.numeroFragmento, numeroFragmento) || other.numeroFragmento == numeroFragmento)&&(identical(other.contenido, contenido) || other.contenido == contenido));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,numeroFragmento,contenido);
}

@override
String toString() {
    return 'FragmentDto(numeroFragmento: $numeroFragmento, contenido: $contenido)';
}


}

/// @nodoc
abstract mixin class _$FragmentDtoCopyWith<$Res> implements $FragmentDtoCopyWith<$Res> {
  factory _$FragmentDtoCopyWith(_FragmentDto value, $Res Function(_FragmentDto) _then) = __$FragmentDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'numero_fragmento') int? numeroFragmento, String contenido
});




}
/// @nodoc
class __$FragmentDtoCopyWithImpl<$Res>
    implements _$FragmentDtoCopyWith<$Res> {
  __$FragmentDtoCopyWithImpl(this._self, this._then);

  final _FragmentDto _self;
  final $Res Function(_FragmentDto) _then;

/// Create a copy of FragmentDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? numeroFragmento = freezed,Object? contenido = null,}) {
  return _then(_FragmentDto(
numeroFragmento: freezed == numeroFragmento ? _self.numeroFragmento : numeroFragmento // ignore: cast_nullable_to_non_nullable
as int?,contenido: null == contenido ? _self.contenido : contenido // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
