/// Parte un texto en fragmentos de ~[size] caracteres, por párrafos, con
/// [overlap] caracteres de solape. Es una copia fiel de `chunking.py` del
/// backend, para que los documentos propios y los del CIE-U se trocen igual.
List<String> chunkText(String text, {int size = 800, int overlap = 100}) {
  final paragraphs = text
      .replaceAll('\r\n', '\n')
      .split('\n\n')
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty);
  final chunks = <String>[];
  var current = '';
  for (var paragraph in paragraphs) {
    while (paragraph.length > size) {
      // Párrafo gigante: se corta duro, con solape entre trozos.
      final head = paragraph.substring(0, size);
      paragraph = paragraph.substring(size - overlap);
      if (current.isNotEmpty) {
        chunks.add(current);
        current = '';
      }
      chunks.add(head);
    }
    if (current.isNotEmpty && current.length + paragraph.length + 2 > size) {
      chunks.add(current);
      final tail = overlap > 0 && current.length > overlap
          ? current.substring(current.length - overlap)
          : (overlap > 0 ? current : '');
      current = '$tail\n\n$paragraph'.trim();
    } else {
      current = current.isNotEmpty
          ? '$current\n\n$paragraph'.trim()
          : paragraph;
    }
  }
  if (current.isNotEmpty) chunks.add(current);
  return chunks;
}
