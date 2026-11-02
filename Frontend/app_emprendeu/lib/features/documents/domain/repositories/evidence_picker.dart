import '../entities/picked_file.dart';

/// Elige un archivo del dispositivo; devuelve `null` si la persona cancela.
abstract interface class EvidencePicker {
  Future<PickedFile?> pick();
}
