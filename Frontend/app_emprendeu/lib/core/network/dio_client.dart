import 'package:dio/dio.dart';

import '../config/app_config.dart';

/// Cliente HTTP base. El token se añade por petición (ver `AuthRemoteDataSource`),
/// así la capa de red no depende de la sesión.
Dio createDio({String baseUrl = AppConfig.apiBaseUrl}) {
  return Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: {'Accept': 'application/json'},
      // Los errores 4xx/5xx llegan como DioException y se mapean a Failure.
      validateStatus: (status) =>
          status != null && status >= 200 && status < 300,
    ),
  );
}
