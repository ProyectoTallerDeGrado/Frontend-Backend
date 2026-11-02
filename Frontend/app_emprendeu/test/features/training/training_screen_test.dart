import 'package:app_emprendeu/core/error/failure.dart';
import 'package:app_emprendeu/features/training/domain/entities/training.dart';
import 'package:app_emprendeu/features/training/domain/usecases/training_usecases.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';
import '../auth/fake_auth_repository.dart';
import 'fake_training_repository.dart';

List<Training> _sample() => [
  Training(
    id: 1,
    title: 'Finanzas básicas',
    date: DateTime(2030, 5, 1, 14),
    modality: 'virtual',
    state: 'publicada',
    enrolledCount: 3,
    enrolled: false,
  ),
  Training(
    id: 2,
    title: 'Marketing digital',
    date: DateTime(2030, 4, 1, 9),
    state: 'publicada',
    enrolledCount: 5,
    enrolled: true,
  ),
  Training(
    id: 3,
    title: 'Taller de ventas',
    date: DateTime(2029, 1, 10),
    state: 'realizada',
    enrolledCount: 8,
    enrolled: true,
    attended: true,
  ),
  Training(
    id: 4,
    title: 'Charla legal',
    date: DateTime(2028, 6, 1),
    state: 'realizada',
    enrolledCount: 8,
    enrolled: true,
    attended: false,
  ),
  Training(
    id: 5,
    title: 'Contabilidad',
    date: DateTime(2028, 3, 1),
    state: 'realizada',
    enrolledCount: 8,
    enrolled: true,
  ),
  Training(
    id: 6,
    title: 'Pitch',
    date: DateTime(2027, 3, 1),
    state: 'realizada',
    enrolledCount: 8,
    enrolled: false,
  ),
];

Future<void> _open(WidgetTester tester, FakeTrainingRepository repo) async {
  await pumpApp(
    tester,
    TestWorld(
      auth: FakeAuthRepository(token: 'tok-1'),
      training: repo,
    ),
    height: 1800,
  );
  await tester.tap(find.text('Perfil'));
  await settle(tester);
  final button = find.text('Capacitaciones');
  await tester.ensureVisible(button);
  await tester.pump(const Duration(milliseconds: 200));
  await tester.tap(button);
  await settle(tester);
}

void main() {
  group('GetPublishedTrainingsUseCase', () {
    test('primero las próximas por fecha y luego las realizadas, la más reciente arriba', () async {
      final result = await GetPublishedTrainingsUseCase(
        FakeTrainingRepository(trainings: _sample()),
      )();
      expect(result.valueOrNull?.map((t) => t.id).toList(), [2, 1, 3, 4, 5, 6]);
    });
  });

  testWidgets('lista las capacitaciones y la asistencia propia (CU29)', (
    tester,
  ) async {
    await _open(tester, FakeTrainingRepository(trainings: _sample()));

    // orden: próximas primero
    final marketing = tester.getTopLeft(find.text('Marketing digital')).dy;
    final finanzas = tester.getTopLeft(find.text('Finanzas básicas')).dy;
    final ventas = tester.getTopLeft(find.text('Taller de ventas')).dy;
    expect(marketing < finanzas && finanzas < ventas, true);

    expect(find.text('Inscrito'), findsOneWidget); // próxima y anotada
    expect(find.text('Inscribirme'), findsOneWidget); // próxima sin anotar
    expect(find.text('Asististe'), findsOneWidget);
    expect(find.text('No asististe'), findsOneWidget);
    expect(find.text('Asistencia sin registrar'), findsOneWidget);
    expect(find.text('No participaste'), findsOneWidget);
    expect(find.text('Próxima'), findsNWidgets(2));
    expect(find.text('Realizada'), findsNWidgets(4));
  });

  testWidgets('se inscribe a una próxima y pasa a «Inscrito»', (tester) async {
    final repo = FakeTrainingRepository(trainings: _sample());
    await _open(tester, repo);

    await tester.tap(find.text('Inscribirme'));
    await settle(tester);

    expect(repo.enrollCalls, 1);
    expect(repo.lastEnrolledId, 1);
    expect(find.text('Inscribirme'), findsNothing);
    expect(find.text('Inscrito'), findsNWidgets(2));
  });

  testWidgets('si no puede inscribirse, explica por qué', (tester) async {
    final repo = FakeTrainingRepository(
      trainings: _sample(),
      enrollFailure: const UnknownFailure(
        'Esta capacitación ya no admite inscripciones.',
      ),
    );
    await _open(tester, repo);
    await tester.tap(find.text('Inscribirme'));
    await settle(tester);
    expect(
      find.text('Esta capacitación ya no admite inscripciones.'),
      findsOneWidget,
    );
    expect(
      find.text('Inscribirme'),
      findsOneWidget,
    ); // sigue sin estar inscrito
  });

  testWidgets('sin capacitaciones publicadas lo dice', (tester) async {
    await _open(tester, FakeTrainingRepository());
    expect(
      find.text('Todavía no hay capacitaciones publicadas.'),
      findsOneWidget,
    );
  });
}
