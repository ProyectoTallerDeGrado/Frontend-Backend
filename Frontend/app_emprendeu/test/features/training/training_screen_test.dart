import 'package:app_emprendeu/features/training/domain/entities/training.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';
import '../auth/fake_auth_repository.dart';
import 'fake_training_repository.dart';

Future<void> _open(WidgetTester tester, FakeTrainingRepository training) async {
  await pumpApp(
    tester,
    TestWorld(
      auth: FakeAuthRepository(token: 'tok-1'),
      training: training,
    ),
    height: 1600,
  );
  await tester.tap(find.text('Perfil'));
  await settle(tester);
  final entry = find.text('Capacitaciones');
  await tester.ensureVisible(entry);
  await tester.pump(const Duration(milliseconds: 200));
  await tester.tap(entry);
  await settle(tester);
}

void main() {
  testWidgets('sin capacitaciones lo dice', (tester) async {
    await _open(tester, FakeTrainingRepository());
    expect(
      find.text('Todavía no hay capacitaciones publicadas.'),
      findsOneWidget,
    );
  });

  testWidgets('muestra la asistencia propia y permite inscribirse', (
    tester,
  ) async {
    final repo = FakeTrainingRepository(
      trainings: [
        const Training(
          id: 1,
          title: 'Finanzas básicas',
          status: 'realizada',
          enrolled: true,
          attended: true,
        ),
        const Training(
          id: 2,
          title: 'Marketing digital',
          status: 'programada',
          enrolled: false,
        ),
      ],
    );
    await _open(tester, repo);
    expect(find.text('Finanzas básicas'), findsOneWidget);
    expect(find.text('Asististe'), findsOneWidget);
    expect(find.text('Inscribirme'), findsOneWidget);

    await tester.tap(find.text('Inscribirme'));
    await settle(tester);
    expect(repo.enrollCalls, 1);
    expect(find.text('Inscribirme'), findsNothing);
    expect(find.text('Inscrito'), findsOneWidget);
  });
}
