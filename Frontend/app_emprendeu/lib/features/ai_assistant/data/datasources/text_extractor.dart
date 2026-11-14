import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:read_pdf_text/read_pdf_text.dart';
import 'package:xml/xml.dart';

/// Saca el texto de un archivo **dentro del celular** (nada se envía a la red).
/// PDF con `read_pdf_text` (PDFBox en Android, PDFKit en iOS), DOCX leyendo su
/// XML, TXT/MD como texto.
/// Lanza `FormatException` si el archivo está dañado o no es lo que dice.
class TextExtractor {
  const TextExtractor();

  Future<String> extract(String path, String name) async {
    final ext = name.split('.').last.toLowerCase();
    return switch (ext) {
      'pdf' => _pdf(path),
      'docx' => docxText(await File(path).readAsBytes()),
      _ => plainText(await File(path).readAsBytes()),
    };
  }

  Future<String> _pdf(String path) async {
    final pages = await ReadPdfText.getPDFtextPaginated(path);
    // Una línea en blanco entre páginas: el troceado corta por párrafos.
    return pages.map((p) => p.trim()).where((p) => p.isNotEmpty).join('\n\n');
  }

  /// Texto de un `.docx`: los párrafos de `word/document.xml`, uno por bloque.
  static String docxText(List<int> bytes) {
    final ArchiveFile? entry;
    try {
      entry = ZipDecoder().decodeBytes(bytes).findFile('word/document.xml');
    } on Object {
      throw const FormatException('No es un archivo Word válido');
    }
    if (entry == null) {
      throw const FormatException('No es un archivo Word válido');
    }
    final xml = XmlDocument.parse(utf8.decode(entry.content));
    return xml
        .findAllElements('w:p')
        .map((p) => p.findAllElements('w:t').map((t) => t.innerText).join())
        .where((t) => t.trim().isNotEmpty)
        .join('\n\n');
  }

  /// UTF-8 (con o sin BOM); si no lo es, Latin-1, como hace el backend.
  static String plainText(List<int> bytes) {
    try {
      final text = utf8.decode(bytes);
      return text.startsWith('﻿') ? text.substring(1) : text;
    } on FormatException {
      return latin1.decode(bytes);
    }
  }
}
