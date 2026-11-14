/// Archivo del emprendedor analizado en su celular para la IA local. El archivo
/// original no se copia: solo se guardan su texto en partes y sus vectores.
class OwnDocument {
  const OwnDocument({
    required this.id,
    required this.name,
    required this.fragments,
    this.addedAt,
  });

  final int id;
  final String name;
  final int fragments;
  final DateTime? addedAt;
}

/// Archivo elegido en el teléfono, todavía sin analizar.
class PickedOwnFile {
  const PickedOwnFile({
    required this.name,
    required this.path,
    required this.sizeBytes,
  });

  final String name;
  final String path;
  final int sizeBytes;
}
