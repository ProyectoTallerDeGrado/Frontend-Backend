import 'dart:io';

import 'package:app_emprendeu/features/documents/data/datasources/documents_remote_data_source.dart';
import 'package:app_emprendeu/features/documents/data/repositories/documents_repository_impl.dart';
import 'package:app_emprendeu/features/documents/domain/entities/evidence.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Escribe un contenido fijo donde el repositorio pida guardar la descarga.
class _FakeRemote implements DocumentsRemoteDataSource {
  int downloads = 0;
  bool fail = false;

  @override
  Future<void> download(int documentId, String savePath) async {
    downloads++;
    if (fail) {
      File(savePath).writeAsStringSync('a medias');
      throw DioException(
        requestOptions: RequestOptions(),
        type: DioExceptionType.connectionError,
      );
    }
    File(savePath).writeAsStringSync('contenido $documentId');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late Directory dir;
  late _FakeRemote remote;
  late DocumentsRepositoryImpl repo;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('docs_download');
    remote = _FakeRemote();
    repo = DocumentsRepositoryImpl(remote, () async => dir);
  });
  tearDown(() => dir.delete(recursive: true));

  test('descarga en el directorio del usuario y reutiliza la copia', () async {
    const doc = Evidence(id: 5, name: 'mi plan: v2.pdf');
    final first = (await repo.download(doc)).valueOrNull!;
    expect(first.name, 'mi plan: v2.pdf');
    expect(first.path, startsWith('${dir.path}/documents/'));
    expect(
      first.path,
      endsWith('5_mi plan_ v2.pdf'),
    ); // nombre de archivo válido
    expect(File(first.path).readAsStringSync(), 'contenido 5');

    await repo.download(doc);
    expect(remote.downloads, 1); // la segunda vez no vuelve a bajarlo
  });

  test('un corte no deja un archivo a medias', () async {
    remote.fail = true;
    final r = await repo.download(const Evidence(id: 6, name: 'x.pdf'));
    expect(r.failureOrNull, isNotNull);
    expect(Directory('${dir.path}/documents').listSync(), isEmpty);
  });
}
