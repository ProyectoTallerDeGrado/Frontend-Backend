@Tags(['integration'])
library;

import 'dart:io';

import 'package:app_emprendeu/core/error/failure.dart';
import 'package:app_emprendeu/core/error/result.dart';
import 'package:app_emprendeu/core/network/auth_interceptor.dart';
import 'package:app_emprendeu/core/network/dio_client.dart';
import 'package:app_emprendeu/core/network/session_events.dart';
import 'package:app_emprendeu/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:app_emprendeu/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:app_emprendeu/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:app_emprendeu/features/auth/domain/usecases/login_usecase.dart';
import 'package:app_emprendeu/features/documents/data/datasources/documents_remote_data_source.dart';
import 'package:app_emprendeu/features/documents/data/repositories/documents_repository_impl.dart';
import 'package:app_emprendeu/features/documents/domain/entities/picked_file.dart';
import 'package:app_emprendeu/features/gamification/data/datasources/gamification_remote_data_source.dart';
import 'package:app_emprendeu/features/gamification/data/repositories/gamification_repository_impl.dart';
import 'package:app_emprendeu/features/training/data/datasources/training_remote_data_source.dart';
import 'package:app_emprendeu/features/training/data/repositories/training_repository_impl.dart';
import 'package:app_emprendeu/features/training/domain/usecases/training_usecases.dart';
import 'package:app_emprendeu/features/ventures/data/datasources/ventures_remote_data_source.dart';
import 'package:app_emprendeu/features/ventures/data/repositories/ventures_repository_impl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';
import 'backend_url.dart';

/// Recorre, contra un backend real, lo que vive una persona que se postula y es admitida:
/// postulación pública → admisión por coordinación → entra a la app con su clave temporal →
/// ve su emprendimiento y su camino, registra una necesidad, ve y se inscribe en una capacitación
/// publicada y sube y elimina un documento.
///
///     flutter test --tags integration test/integration \
///       --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1 \
///       --dart-define=E2E_ADMIN_EMAIL=admin@correo.com --dart-define=E2E_ADMIN_PASSWORD=...
///
/// (En un emulador de Android, `10.0.2.2` en lugar de `127.0.0.1`.)
void main() {
  final baseUrl = backendUrl();
  final admin = adminCredentials();
  final skip = baseUrl == null || admin == null
      ? 'Define API_BASE_URL, E2E_ADMIN_EMAIL y E2E_ADMIN_PASSWORD para correrla'
      : null;

  test(
    'postulación, admisión y primer día del emprendedor en la app',
    skip: skip,
    () async {
      final stamp = DateTime.now().microsecondsSinceEpoch;

      // --- personal: lo que hace la coordinación (cliente HTTP sin sesión de la app) ---------------
      final staff = createDio(baseUrl: baseUrl!);
      Future<Map<String, dynamic>> call(
        String method,
        String path, {
        Object? data,
        String? token,
      }) async {
        final r = await staff.request<Object>(
          path,
          data: data,
          options: Options(
            method: method,
            headers: {
              'Authorization': ?(token == null ? null : 'Bearer $token'),
            },
          ),
        );
        final body = r.data;
        return body is Map<String, dynamic> ? body : {'items': body};
      }

      final adminToken =
          (await call(
                'POST',
                '/auth/login',
                data: {'email': admin!.email, 'password': admin.password},
              ))['access_token']
              as String;
      const staffPassword = 'clave-coord-1234';
      final coordEmail = 'coord-it-$stamp@correo.com';
      await call(
        'POST',
        '/users',
        token: adminToken,
        data: {
          'nombre_completo': 'Coordinadora Integracion',
          'email': coordEmail,
          'rol': 'coordinador',
          'password': staffPassword,
        },
      );
      final coord =
          (await call(
                'POST',
                '/auth/login',
                data: {'email': coordEmail, 'password': staffPassword},
              ))['access_token']
              as String;

      // Postulación pública y admisión.
      final email = 'lucia-it-$stamp@correo.com';
      await call(
        'POST',
        '/applications',
        data: {
          'nombre': 'Lucía María',
          'apellido': 'Vargas',
          'email': email,
          'documento_identidad': 'IT-$stamp',
          'nombre_emprendimiento': 'Dulces IT $stamp',
          'sector': 'Alimentos',
        },
      );
      final pending = await call(
        'GET',
        '/applications?estado=pendiente&q=$email',
        token: coord,
      );
      // La página ya es un mapa con `items`.
      final applicationId =
          (pending['items'] as List).first['postulacion_id'] as int;
      final admitted = await call(
        'POST',
        '/applications/$applicationId/admit',
        token: coord,
        data: <String, dynamic>{},
      );
      final temporaryPassword = admitted['temporary_password'] as String;

      // Una capacitación publicada.
      final training = await call(
        'POST',
        '/training',
        token: coord,
        data: {'titulo': 'Finanzas IT $stamp', 'fecha': '2030-06-01T14:00:00Z'},
      );
      await call(
        'PATCH',
        '/training/${training['capacitacion_id']}',
        token: coord,
        data: {'estado': 'publicada'},
      );

      // --- la app: la persona admitida entra con la clave temporal --------------------------------
      final tokens = InMemoryTokenStorage();
      final dio = createDio(baseUrl: baseUrl)
        ..interceptors.add(AuthInterceptor(tokens, SessionEvents()));
      final authRepo = AuthRepositoryImpl(
        AuthRemoteDataSource(dio),
        AuthLocalDataSource(tokens),
      );
      final session = (await LoginUseCase(authRepo)(
        email,
        temporaryPassword,
      )).getOrThrow();
      expect(session.user.isEntrepreneur, isTrue);

      // Su emprendimiento ya existe, en la primera etapa, y su camino está listo.
      final ventures = VenturesRepositoryImpl(VenturesRemoteDataSource(dio));
      final venture = (await ventures.getMine()).getOrThrow()!;
      expect(venture.name, 'Dulces IT $stamp');
      expect(venture.stageName, isNotNull);
      expect(venture.sector, 'Alimentos');
      final journey = await GamificationRepositoryImpl(
        GamificationRemoteDataSource(dio),
      ).getJourney();
      expect(journey.getOrThrow().challenges, isNotEmpty);

      // CU24: registra una necesidad; repetirla sin resolver da el aviso.
      final need = (await ventures.addNeed(
        venture.id,
        name: 'Capital de trabajo',
        priority: 'alta',
      )).getOrThrow();
      expect(need.resolved, isFalse);
      final repeated = await ventures.addNeed(
        venture.id,
        name: 'capital de trabajo',
        priority: 'media',
      );
      expect(repeated.failureOrNull, isA<FieldFailure>());
      expect((await ventures.getNeeds(venture.id)).getOrThrow().length, 1);
      expect(
        (await ventures.resolveNeed(need.id)).getOrThrow().resolved,
        isTrue,
      );

      // CU29: ve la capacitación publicada y se inscribe.
      final trainingRepo = TrainingRepositoryImpl(
        TrainingRemoteDataSource(dio),
      );
      final published = (await GetPublishedTrainingsUseCase(
        trainingRepo,
      )()).getOrThrow();
      final mine = published.firstWhere((t) => t.title == 'Finanzas IT $stamp');
      expect(mine.enrolled, isFalse);
      expect((await trainingRepo.enroll(mine.id)).failureOrNull, isNull);
      final after = (await trainingRepo.getPublished()).getOrThrow().firstWhere(
        (t) => t.id == mine.id,
      );
      expect(after.enrolled, isTrue);
      expect(after.attended, isNull); // la asistencia aún no se registró

      // CU30: sube un documento, lo ve en la lista y lo elimina. (Descargar usa un plugin de
      // plataforma: se prueba con dobles.)
      final file = File('${Directory.systemTemp.path}/plan-it-$stamp.pdf')
        ..writeAsBytesSync('%PDF-1.4 integracion'.codeUnits);
      addTearDown(() {
        if (file.existsSync()) file.deleteSync();
      });
      final documents = DocumentsRepositoryImpl(DocumentsRemoteDataSource(dio));
      final uploaded = (await documents.upload(
        ventureId: venture.id,
        file: PickedFile(name: 'plan-it-$stamp.pdf', path: file.path),
      )).getOrThrow();
      final listed = (await documents.listForVenture(venture.id)).getOrThrow();
      expect(listed.map((d) => d.name), contains('plan-it-$stamp.pdf'));
      expect((await documents.delete(uploaded.id)).failureOrNull, isNull);
      expect(
        (await documents.listForVenture(venture.id)).getOrThrow(),
        isEmpty,
      );
    },
  );
}
