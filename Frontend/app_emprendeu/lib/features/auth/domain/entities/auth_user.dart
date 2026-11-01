/// Usuario autenticado (objeto de negocio puro).
class AuthUser {
  const AuthUser({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.rol,
    this.permisos = const [],
  });

  final int id;
  final String nombre;
  final String apellido;
  final String email;
  final String? rol;
  final List<String> permisos;

  String get fullName => '$nombre $apellido'.trim();

  /// Esta app es para emprendedores; el resto de roles usa el panel web.
  bool get isEntrepreneur => rol == 'emprendedor';
}
