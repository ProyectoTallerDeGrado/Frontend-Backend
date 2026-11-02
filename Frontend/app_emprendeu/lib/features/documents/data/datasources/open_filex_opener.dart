import 'package:open_filex/open_filex.dart';

import '../../domain/repositories/file_opener.dart';

/// Abre archivos con `open_filex` (visor del sistema).
class OpenFilexOpener implements FileOpener {
  const OpenFilexOpener();

  @override
  Future<bool> open(String path) async =>
      (await OpenFilex.open(path)).type == ResultType.done;
}
