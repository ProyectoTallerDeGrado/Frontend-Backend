import 'package:dio/dio.dart';

import '../models/mentoring_dto.dart';
import '../models/pending_op.dart';

class MentoringRemoteDataSource {
  const MentoringRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<CommitmentDto>> commitments() async {
    final response = await _dio.get<List<dynamic>>('/mentoring/commitments/me');
    return response.data!
        .map((e) => CommitmentDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CommitmentDto> setCommitmentDone(
    int id,
    bool done, {
    DateTime? at,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/mentoring/commitments/$id',
      data: {
        'completado': done,
        if (at != null) 'fecha': at.toUtc().toIso8601String(),
      },
    );
    return CommitmentDto.fromJson(response.data!);
  }

  Future<List<ProgressDto>> progress({int? ventureId}) async {
    final response = await _dio.get<List<dynamic>>(
      '/mentoring/progress',
      queryParameters: {'emprendimiento_id': ?ventureId},
    );
    return response.data!
        .map((e) => ProgressDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ProgressDto> logProgress(
    String text,
    String clientRef, {
    DateTime? at,
    int? ventureId,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/mentoring/progress',
      data: {
        'observaciones': text,
        'referencia_cliente': clientRef,
        if (at != null) 'fecha': at.toUtc().toIso8601String(),
        'emprendimiento_id': ?ventureId,
      },
    );
    return ProgressDto.fromJson(response.data!);
  }

  Future<SyncResultDto> sync(List<PendingOp> ops) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/mentoring/sync',
      data: {
        'avances': [
          for (final op in ops.whereType<PendingProgressOp>())
            {
              'observaciones': op.text,
              'referencia_cliente': op.clientRef,
              'fecha': op.at.toUtc().toIso8601String(),
              'emprendimiento_id': ?op.ventureId,
            },
        ],
        'compromisos': [
          for (final op in ops.whereType<PendingCommitmentOp>())
            {
              'compromiso_id': op.commitmentId,
              'completado': op.done,
              'fecha': op.at.toUtc().toIso8601String(),
            },
        ],
      },
    );
    return SyncResultDto.fromJson(response.data!);
  }
}
