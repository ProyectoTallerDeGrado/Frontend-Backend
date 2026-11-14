import 'dart:convert';
import 'dart:io';

import 'package:app_emprendeu/features/ai_assistant/domain/usecases/chunk_text.dart';
import 'package:flutter_test/flutter_test.dart';

/// Los casos y sus resultados se generaron con `chunking.py` del backend: el
/// celular debe trocear exactamente igual.
void main() {
  final cases = (jsonDecode(
    File('test/features/ai_assistant/chunk_text_fixture.json')
        .readAsStringSync(),
  ) as List).cast<Map<String, dynamic>>();

  for (final c in cases) {
    test('igual que el backend: ${c['name']}', () {
      expect(
        chunkText(c['input'] as String),
        (c['expected'] as List).cast<String>(),
      );
    });
  }

  test('un texto vacío no da fragmentos', () {
    expect(chunkText('  \n\n  '), isEmpty);
  });
}
