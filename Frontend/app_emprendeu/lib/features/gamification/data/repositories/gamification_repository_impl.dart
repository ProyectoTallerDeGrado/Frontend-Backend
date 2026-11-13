import 'package:dio/dio.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../../domain/entities/completion_result.dart';
import '../../domain/entities/gamification_profile.dart';
import '../../domain/entities/journey.dart';
import '../../domain/repositories/gamification_repository.dart';
import '../datasources/gamification_remote_data_source.dart';

class GamificationRepositoryImpl implements GamificationRepository {
  const GamificationRepositoryImpl(this._remote);

  final GamificationRemoteDataSource _remote;

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Result.ok(await action());
    } on DioException catch (e) {
      final failure = mapDioException(e);
      // El backend responde `no_venture` (409) si el usuario aún no registró su emprendimiento.
      if (e.response?.statusCode == 409 &&
          (e.response?.data as Map?)?['error']?['code'] == 'no_venture') {
        return const Result.err(NoVentureFailure());
      }
      return Result.err(failure);
    } on TypeError {
      return const Result.err(
        UnknownFailure('Respuesta inválida del servidor.'),
      );
    }
  }

  @override
  Future<Result<Journey>> getJourney({int? ventureId}) => _guard(
    () async => (await _remote.journey(ventureId: ventureId)).toEntity(),
  );

  @override
  Future<Result<CompletionResult>> completeChallenge(
    int challengeId, {
    int? ventureId,
    String? evidenceText,
    int? documentId,
  }) => _guard(
    () async => (await _remote.complete(
      challengeId,
      ventureId: ventureId,
      evidenceText: evidenceText,
      documentId: documentId,
    )).toEntity(),
  );

  @override
  Future<Result<GamificationProfile>> getProfile() =>
      _guard(() async => (await _remote.profile()).toEntity());
}
