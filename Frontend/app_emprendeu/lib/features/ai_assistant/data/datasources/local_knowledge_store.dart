import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

/// Un fragmento guardado en el celular, con su vector y su norma precalculada.
class StoredFragment {
  StoredFragment(this.text, this.vector)
    : norm = math.sqrt(vector.fold<double>(0, (s, x) => s + x * x));

  final String text;
  final Float32List vector;
  final double norm;
}

class StoredDocument {
  StoredDocument({
    required this.id,
    required this.title,
    required this.loadedAt,
    required this.fragments,
  });

  final int id;
  final String title;

  /// `fecha_carga` del servidor: si cambia, el documento se vuelve a bajar.
  final DateTime? loadedAt;
  final List<StoredFragment> fragments;
}

class StoredIndex {
  StoredIndex({
    required this.embedderId,
    required this.documents,
    this.syncedAt,
  });

  /// Modelo con el que se calcularon los vectores.
  final String embedderId;
  final Map<int, StoredDocument> documents;
  DateTime? syncedAt;

  int get fragmentCount =>
      documents.values.fold(0, (s, d) => s + d.fragments.length);
}

/// Índice local de la base de conocimiento: un archivo JSON en el directorio de
/// soporte de la app (no es dato del usuario: no se borra al cerrar sesión).
/// Los vectores van como `Float32` en base64 para ocupar ~4 bytes por número.
class LocalKnowledgeStore {
  LocalKnowledgeStore(this._directory, {this.fileName = defaultFileName});

  final Future<Directory> Function() _directory;

  /// Archivo del índice dentro del directorio.
  final String fileName;
  static const defaultFileName = 'coach_knowledge_index.json';
  static const _version = 1;

  StoredIndex? _cache;

  Future<File> _file() async => File('${(await _directory()).path}/$fileName');

  /// Índice guardado. Si no existe, está dañado o es de otro modelo, uno vacío.
  Future<StoredIndex> load(String embedderId) async {
    final file = await _file();
    final cached = _cache;
    // Si el archivo desapareció (cerrar sesión borra los del usuario), la copia
    // en memoria tampoco vale: así otra cuenta no ve los datos de la anterior.
    if (cached != null &&
        cached.embedderId == embedderId &&
        (cached.documents.isEmpty || await file.exists())) {
      return cached;
    }
    StoredIndex index = StoredIndex(embedderId: embedderId, documents: {});
    if (await file.exists()) {
      try {
        final parsed = _decode(
          jsonDecode(await file.readAsString()) as Map<String, dynamic>,
        );
        if (parsed.embedderId == embedderId) index = parsed;
      } on Object {
        // Archivo dañado: se reconstruye en la próxima sincronización.
      }
    }
    return _cache = index;
  }

  /// Escribe a un temporal y lo renombra: un corte no deja el archivo a medias.
  Future<void> save(StoredIndex index) async {
    final file = await _file();
    await file.parent.create(recursive: true);
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(jsonEncode(_encode(index)), flush: true);
    await tmp.rename(file.path);
    _cache = index;
  }

  static Map<String, dynamic> _encode(StoredIndex index) => {
    'version': _version,
    'embedder': index.embedderId,
    'synced_at': index.syncedAt?.toUtc().toIso8601String(),
    'documents': [
      for (final d in index.documents.values)
        {
          'id': d.id,
          'title': d.title,
          'loaded_at': d.loadedAt?.toUtc().toIso8601String(),
          'fragments': [
            for (final f in d.fragments)
              {
                't': f.text,
                'v': base64Encode(
                  f.vector.buffer.asUint8List(
                    f.vector.offsetInBytes,
                    f.vector.lengthInBytes,
                  ),
                ),
              },
          ],
        },
    ],
  };

  static StoredIndex _decode(Map<String, dynamic> json) {
    if (json['version'] != _version) {
      throw const FormatException('Versión de índice desconocida');
    }
    final docs = <int, StoredDocument>{};
    for (final raw in json['documents'] as List) {
      final d = raw as Map<String, dynamic>;
      final id = d['id'] as int;
      docs[id] = StoredDocument(
        id: id,
        title: d['title'] as String,
        loadedAt: d['loaded_at'] == null
            ? null
            : DateTime.parse(d['loaded_at'] as String),
        fragments: [
          for (final f in (d['fragments'] as List).cast<Map<String, dynamic>>())
            StoredFragment(
              f['t'] as String,
              Uint8List.fromList(base64Decode(f['v'] as String)).buffer
                  .asFloat32List(),
            ),
        ],
      );
    }
    return StoredIndex(
      embedderId: json['embedder'] as String,
      documents: docs,
      syncedAt: json['synced_at'] == null
          ? null
          : DateTime.parse(json['synced_at'] as String),
    );
  }
}
