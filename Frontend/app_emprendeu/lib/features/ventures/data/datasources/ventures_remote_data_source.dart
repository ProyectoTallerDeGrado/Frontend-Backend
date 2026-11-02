import 'package:dio/dio.dart';

import '../models/milestone_dto.dart';
import '../models/need_dto.dart';
import '../models/venture_dto.dart';

class VenturesRemoteDataSource {
  const VenturesRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<VentureDto>> mine() async {
    final response = await _dio.get<List<dynamic>>('/ventures/me');
    return response.data!
        .map((e) => VentureDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<VentureDto> create(String name) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/ventures',
      data: {'nombre': name},
    );
    return VentureDto.fromJson(response.data!);
  }

  Future<VentureDto> update(
    int ventureId, {
    required String name,
    String? description,
    String? sector,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/ventures/$ventureId',
      data: {'nombre': name, 'descripcion': description, 'sector': sector},
    );
    return VentureDto.fromJson(response.data!);
  }

  Future<List<MilestoneDto>> milestones(int ventureId) async {
    final response = await _dio.get<List<dynamic>>(
      '/ventures/$ventureId/milestones',
    );
    return response.data!
        .map((e) => MilestoneDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<MilestoneDto> createMilestone(
    int ventureId, {
    required String title,
    String? description,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/ventures/$ventureId/milestones',
      data: {'titulo': title, 'descripcion': description},
    );
    return MilestoneDto.fromJson(response.data!);
  }

  Future<MilestoneDto> completeMilestone(int milestoneId) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/milestones/$milestoneId',
      data: {'estado': 'cumplido'},
    );
    return MilestoneDto.fromJson(response.data!);
  }

  Future<List<VentureNeedDto>> needs(int ventureId) async {
    final response = await _dio.get<List<dynamic>>(
      '/ventures/$ventureId/needs',
    );
    return response.data!
        .map((e) => VentureNeedDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<VentureNeedDto> addNeed(
    int ventureId, {
    required String name,
    required String priority,
    String? description,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/ventures/$ventureId/needs',
      data: {
        'nombre': name,
        'prioridad': priority,
        'descripcion': ?description,
      },
    );
    return VentureNeedDto.fromJson(response.data!);
  }

  Future<VentureNeedDto> resolveNeed(int needId) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/venture-needs/$needId/resolve',
    );
    return VentureNeedDto.fromJson(response.data!);
  }

  Future<List<NeedCatalogDto>> needCatalog() async {
    final response = await _dio.get<List<dynamic>>('/needs');
    return response.data!
        .map((e) => NeedCatalogDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
