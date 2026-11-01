import 'package:dio/dio.dart';

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
}
