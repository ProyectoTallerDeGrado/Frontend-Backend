import 'package:app_emprendeu/app/app.dart';
import 'package:app_emprendeu/core/connectivity/online_controller.dart';
import 'package:app_emprendeu/core/storage/providers.dart';
import 'package:app_emprendeu/features/ai_assistant/index.dart';
import 'package:app_emprendeu/features/auth/index.dart';
import 'package:app_emprendeu/features/documents/index.dart';
import 'package:app_emprendeu/features/gamification/index.dart';
import 'package:app_emprendeu/features/mentoring/index.dart';
import 'package:app_emprendeu/features/needs/index.dart';
import 'package:app_emprendeu/features/training/index.dart';
import 'package:app_emprendeu/features/ventures/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/ai_assistant/fake_assistant_repository.dart';
import '../features/auth/fake_auth_repository.dart';
import '../features/documents/fake_documents.dart';
import '../features/mentoring/fake_booking_repository.dart';
import '../features/needs/fake_needs_repository.dart';
import '../features/training/fake_training_repository.dart';
import 'fakes.dart';

/// Todo lo que una prueba de pantalla puede querer ajustar.
class TestWorld {
  TestWorld({
    FakeAuthRepository? auth,
    FakeVenturesRepository? ventures,
    FakeGamificationRepository? gamification,
    FakeMentoringRepository? mentoring,
    FakeBookingRepository? booking,
    FakeDocumentsRepository? documents,
    FakeAssistantRepository? assistant,
    FakeNeedsRepository? needs,
    FakeTrainingRepository? training,
    FakeEvidencePicker? picker,
    FakeConnectivity? connectivity,
  }) : auth = auth ?? FakeAuthRepository(),
       ventures =
           ventures ??
           FakeVenturesRepository(
             venture: const Venture(
               id: 1,
               name: 'Sabores del Oriente',
               stageName: 'Incubación',
             ),
           ),
       gamification = gamification ?? FakeGamificationRepository(),
       mentoring = mentoring ?? FakeMentoringRepository(),
       booking = booking ?? FakeBookingRepository(),
       documents = documents ?? FakeDocumentsRepository(),
       assistant = assistant ?? FakeAssistantRepository(),
       needs = needs ?? FakeNeedsRepository(),
       training = training ?? FakeTrainingRepository(),
       picker = picker ?? FakeEvidencePicker(),
       connectivity = connectivity ?? FakeConnectivity();

  final FakeAuthRepository auth;
  final FakeVenturesRepository ventures;
  final FakeGamificationRepository gamification;
  final FakeMentoringRepository mentoring;
  final FakeBookingRepository booking;
  final FakeDocumentsRepository documents;
  final FakeAssistantRepository assistant;
  final FakeNeedsRepository needs;
  final FakeTrainingRepository training;
  final FakeEvidencePicker picker;
  final FakeConnectivity connectivity;
  final store = InMemoryKeyValueStore();
}

Future<void> pumpApp(
  WidgetTester tester,
  TestWorld world, {
  double height = 844,
}) async {
  tester.view.physicalSize = Size(390 * 3, height * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        authRepositoryProvider.overrideWithValue(world.auth),
        venturesRepositoryProvider.overrideWithValue(world.ventures),
        gamificationRepositoryProvider.overrideWithValue(world.gamification),
        mentoringRepositoryProvider.overrideWithValue(world.mentoring),
        bookingRepositoryProvider.overrideWithValue(world.booking),
        documentsRepositoryProvider.overrideWithValue(world.documents),
        assistantRepositoryProvider.overrideWithValue(world.assistant),
        needsRepositoryProvider.overrideWithValue(world.needs),
        trainingRepositoryProvider.overrideWithValue(world.training),
        evidencePickerProvider.overrideWithValue(world.picker),
        connectivitySourceProvider.overrideWithValue(world.connectivity),
        keyValueStoreProvider.overrideWithValue(world.store),
        // El reintento periódico no interviene en las pruebas.
        syncRetryIntervalProvider.overrideWithValue(const Duration(hours: 1)),
      ],
      child: const App(useGoogleFonts: false),
    ),
  );
  await settle(tester);
}

/// Deja avanzar animaciones y futuros (las animaciones infinitas impiden `pumpAndSettle`).
Future<void> settle(WidgetTester tester, {int frames = 6}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}
