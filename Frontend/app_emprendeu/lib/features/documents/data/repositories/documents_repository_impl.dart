import 'package:dio/dio.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../domain/entities/evidence.dart';
import '../../domain/entities/picked_file.dart';
import '../../domain/repositories/documents_repository.dart';
import '../datasources/documents_remote_data_source.dart';

class DocumentsRepositoryImpl implements DocumentsRepository {
  const DocumentsRepositoryImpl(this._remote);

  final DocumentsRemoteDataSource _remote;

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
  Future<Result<List<Evidence>>> listForVenture(int ventureId) => _guard(
    () async => [
      for (final d in await _remote.listForVenture(ventureId)) d.toEntity(),
    ],
  );
}
