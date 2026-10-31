import 'dart:math';

/// Identificador generado en el dispositivo para registros creados sin conexión.
/// El backend lo usa para no duplicar un mismo registro si se reenvía.
String generateClientRef() {
  final random = Random.secure();
  final bytes = List<int>.generate(12, (_) => random.nextInt(256));
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}
