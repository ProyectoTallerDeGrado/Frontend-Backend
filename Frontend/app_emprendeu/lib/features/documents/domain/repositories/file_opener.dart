/// Abre un archivo local con la app que corresponda del dispositivo.
abstract interface class FileOpener {
  /// `false` si no hay una app capaz de abrirlo.
  Future<bool> open(String path);
}
