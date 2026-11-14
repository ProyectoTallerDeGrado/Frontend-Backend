/// Copia local de un documento del servidor, guardada en el almacenamiento
/// privado del usuario (se borra al cerrar sesión).
class DownloadedDocument {
  const DownloadedDocument({
    required this.name,
    required this.path,
    this.sizeBytes = 0,
  });

  final String name;
  final String path;
  final int sizeBytes;
}
