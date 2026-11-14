import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Directorio privado de la app para archivos **del usuario con sesión**.
/// `LocalDataCleaner` lo borra entero al cerrar sesión: guarda aquí todo archivo
/// que no deba ver la siguiente cuenta.
Future<Directory> userFilesDirectory() async =>
    Directory('${(await getApplicationSupportDirectory()).path}/user_files');
