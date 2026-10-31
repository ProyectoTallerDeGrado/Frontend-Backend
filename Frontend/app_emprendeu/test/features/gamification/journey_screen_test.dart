import 'package:app_emprendeu/core/error/failure.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../../support/test_app.dart';
import '../auth/fake_auth_repository.dart';

Future<void> _goToJourney(WidgetTester tester, TestWorld world) async {
  await pumpApp(tester, world);
  await tester.tap(find.text('Camino'));
  await settle(tester, frames: 10);
}

TestWorld _world({
  FakeGamificationRepository? gamification,
  FakeVenturesRepository? ventures,
}) => TestWorld(
  auth: FakeAuthRepositoryWithToken(),
  gamification: gamification,
  ventures: ventures,
);

void main() {
  testWidgets('el camino muestra etapas, XP y el estado de cada reto', (
    tester,
  ) async {
    await _goToJourney(tester, _world());

    expect(find.text('Mi camino'), findsOneWidget);
    expect(find.text('295 XP'), findsOneWidget);
    expect(find.text('Preincubación'), findsOneWidget);
    expect(find.text('Incubación'), findsOneWidget);
    expect(find.text('Crecimiento', skipOffstage: false), findsOneWidget);
    expect(find.text('Cumplido · +100 XP'), findsOneWidget);
    expect(find.text('En curso · +150 XP'), findsOneWidget);
    expect(find.text('Bloqueado'), findsWidgets);
  });

  testWidgets('un reto bloqueado explica por qué y no se puede cumplir', (
    tester,
  ) async {
    await _goToJourney(tester, _world());

    await tester.tap(find.bySemanticsLabel(RegExp('Reto 4: .*bloqueado')));
    await settle(tester);

    expect(
      find.text('Completa el reto anterior para desbloquearlo.'),
      findsOneWidget,
    );
    expect(find.text('Marcar como cumplido'), findsNothing);
  });

  testWidgets('cumplir el reto en curso suma XP y desbloquea el siguiente', (
    tester,
  ) async {
    final repo = FakeGamificationRepository();
    await _goToJourney(tester, _world(gamification: repo));

    await tester.tap(find.bySemanticsLabel(RegExp('Reto 3: .*en curso')));
    await settle(tester);
    expect(find.text('Construir un prototipo mínimo'), findsWidgets);
    await tester.tap(find.text('Marcar como cumplido'));
    await settle(tester, frames: 12);

    expect(repo.completeCalls, 1);
    expect(find.text('+150 XP'), findsOneWidget); // burbuja
    expect(find.text('445 XP'), findsOneWidget);
    expect(find.text('En curso · +175 XP'), findsOneWidget); // ahora el reto 4
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('si el servidor rechaza cumplir el reto se muestra el motivo', (
    tester,
  ) async {
    final repo = FakeGamificationRepository()
      ..completeFailure = const NetworkFailure();
    await _goToJourney(tester, _world(gamification: repo));

    await tester.tap(find.bySemanticsLabel(RegExp('Reto 3: .*en curso')));
    await settle(tester);
    await tester.tap(find.text('Marcar como cumplido'));
    await settle(tester);

    expect(
      find.textContaining('No se pudo conectar con el servidor'),
      findsOneWidget,
    );
    expect(find.text('Marcar como cumplido'), findsOneWidget);
  });

  testWidgets('sin emprendimiento el camino pide registrarlo', (tester) async {
    final repo = FakeGamificationRepository(
      journeyFailure: const NoVentureFailure(),
    );
    await _goToJourney(
      tester,
      _world(gamification: repo, ventures: FakeVenturesRepository()),
    );

    expect(find.text('Registra tu emprendimiento'), findsOneWidget);
  });
}
