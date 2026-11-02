import 'package:dio/dio.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../domain/entities/training.dart';
import '../../domain/repositories/training_repository.dart';
import '../datasources/training_remote_data_source.dart';

class TrainingRepositoryImpl implements TrainingRepository {
  const TrainingRepositoryImpl(this._remote);

  final TrainingRemoteDataSource _remote;

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Result.ok(await action());
    } on DioException catch (e) {
      final code = _code(e);
      if (code == 'already_enrolled') {
        return const Result.err(
          UnknownFailure('Ya estás inscrito en esta capacitación.'),
        );
      }
      if (code == 'training_not_open') {
        return const Result.err(
          UnknownFailure('Esta capacitación ya no admite inscripciones.'),
        );
      }
      return Result.err(mapDioException(e));
    } on TypeError {
      return const Result.err(
        UnknownFailure('Respuesta inválida del servidor.'),
      );
    }
  }

  static String? _code(DioException e) {
    final data = e.response?.data;
    final error = data is Map ? data['error'] : null;
    return error is Map ? error['code'] as String? : null;
  }

  @override
  Future<Result<List<Training>>> getPublished() => _guard(
    () async => [for (final t in await _remote.published()) t.toEntity()],
  );

  @override
  Future<Result<void>> enroll(int trainingId) =>
      _guard(() => _remote.enroll(trainingId));
}
