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
      if (e.response?.statusCode == 409) {
        return const Result.err(
          UnknownFailure('Ya estás inscrito en esta capacitación.'),
        );
      }
      return Result.err(mapDioException(e));
    } on TypeError {
      return const Result.err(
        UnknownFailure('Respuesta inválida del servidor.'),
      );
    }
  }

  @override
  Future<Result<List<Training>>> getTrainings() => _guard(() async {
    final mine = {for (final t in await _remote.mine()) t.capacitacionId: t};
    final all = await _remote.all();
    final ids = {for (final t in all) t.capacitacionId};
    return [
      for (final t in all)
        mine[t.capacitacionId]?.toEntity(enrolled: true) ??
            t.toEntity(enrolled: false),
      // Las ya realizadas o canceladas en las que participó pueden no salir en la lista general.
      for (final t in mine.values)
        if (!ids.contains(t.capacitacionId)) t.toEntity(enrolled: true),
    ];
  });

  @override
  Future<Result<Training>> enroll(int trainingId) => _guard(
    () async => (await _remote.enroll(trainingId)).toEntity(enrolled: true),
  );
}
