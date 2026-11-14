import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../domain/entities/downloaded_document.dart';
import '../../domain/entities/evidence.dart';
import '../../domain/entities/picked_file.dart';
import '../../domain/repositories/documents_repository.dart';
import '../datasources/documents_remote_data_source.dart';

class DocumentsRepositoryImpl implements DocumentsRepository {
  const DocumentsRepositoryImpl(this._remote, this._userFiles);

  final DocumentsRemoteDataSource _remote;

  /// Directorio privado del usuario: las descargas se borran al cerrar sesión.
  final Future<Directory> Function() _userFiles;

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Result.ok(await action());
    } on DioException catch (e) {
      if (e.response?.statusCode == 415) {
        return const Result.err(
          FieldFailure('file', 'Ese tipo de archivo no es válido.'),
        );
      }
      if (e.response?.statusCode == 413) {
        return const Result.err(
          FieldFailure('file', 'El archivo es demasiado grande.'),
        );
      }
      return Result.err(mapDioException(e));
    } on TypeError {
      return const Result.err(
        UnknownFailure('Respuesta inválida del servidor.'),
      );
    } on Exception {
      // Archivo ilegible o movido antes de subirlo.
      return const Result.err(
        UnknownFailure('No se pudo leer el archivo elegido.'),
      );
    }
  }

  @override
  Future<Result<Evidence>> upload({
    required int ventureId,
    int? milestoneId,
    required PickedFile file,
  }) => _guard(
    () async => (await _remote.upload(
      ventureId: ventureId,
      milestoneId: milestoneId,
      file: file,
    )).toEntity(),
  );

  @override
  Future<Result<void>> delete(int documentId) =>
      _guard(() => _remote.delete(documentId));

  @override
  Future<Result<List<Evidence>>> listForVenture(int ventureId) => _guard(
    () async => [
      for (final d in await _remote.listForVenture(ventureId)) d.toEntity(),
    ],
  );

  @override
  Future<Result<DownloadedDocument>> download(Evidence document) =>
      _guard(() async {
        final dir = Directory('${(await _userFiles()).path}/documents');
        await dir.create(recursive: true);
        // El id evita choques entre archivos con el mismo nombre; el nombre se
        // limpia para que sea un nombre de archivo válido.
        final safe = document.name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
        final file = File('${dir.path}/${document.id}_$safe');
        // Un documento del servidor no cambia: si ya se bajó, se reutiliza.
        if (!await file.exists()) {
          final partial = File('${file.path}.part');
          try {
            await _remote.download(document.id, partial.path);
            await partial.rename(file.path);
          } finally {
            if (await partial.exists()) await partial.delete();
          }
        }
        return DownloadedDocument(
          name: document.name,
          path: file.path,
          sizeBytes: await file.length(),
        );
      });
}
