import 'package:open_filex/open_filex.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/repositories/file_opener.dart';

/// Abre archivos con la app del sistema (`open_filex`).
class OpenFilexFileOpener implements FileOpener {
  const OpenFilexFileOpener();

  @override
  Future<Result<void>> open(String path) async {
    try {
      final result = await OpenFilex.open(path);
      return switch (result.type) {
        ResultType.done => const Ok(null),
        ResultType.noAppToOpen => const Err(
          UnknownFailure(
            'No tienes una app para abrir este tipo de archivo. '
            'Instala un visor (por ejemplo, de PDF) e intenta de nuevo.',
          ),
        ),
        ResultType.fileNotFound => const Err(
          UnknownFailure('El archivo descargado ya no está. Ábrelo de nuevo.'),
        ),
        _ => const Err(UnknownFailure('No se pudo abrir el archivo.')),
      };
    } on Object {
      return const Err(UnknownFailure('No se pudo abrir el archivo.'));
    }
  }
}
