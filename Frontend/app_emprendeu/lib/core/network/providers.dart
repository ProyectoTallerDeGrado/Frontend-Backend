import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/providers.dart';
import 'auth_interceptor.dart';
import 'dio_client.dart';
import 'session_events.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = createDio();
  dio.interceptors.add(
    AuthInterceptor(
      ref.watch(tokenStorageProvider),
      ref.watch(sessionEventsProvider),
    ),
  );
  ref.onDispose(dio.close);
  return dio;
});
