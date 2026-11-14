import '../../../../core/error/result.dart';

/// Abre un archivo local con la app del sistema que corresponda (visor de PDF, etc.).
abstract interface class FileOpener {
  Future<Result<void>> open(String path);
}
