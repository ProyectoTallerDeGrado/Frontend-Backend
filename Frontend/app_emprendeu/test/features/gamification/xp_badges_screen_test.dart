import 'package:app_emprendeu/core/error/failure.dart';
import 'package:app_emprendeu/features/gamification/domain/entities/gamification_profile.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../../support/test_app.dart';
import '../auth/fake_auth_repository.dart';

TestWorld _world(FakeGamificationRepository gamification) =>
    TestWorld(auth: FakeAuthRepositoryWithToken(), gamification: gamification);

Future<void> _openProfile(WidgetTester tester, TestWorld world) async {
  await pumpApp(tester, world);
  await tester.tap(find.text('Perfil'));
  await settle(tester, frames: 10);
}

Future<void> _openXpScreen(WidgetTester tester, TestWorld world) async {
  await _openProfile(tester, world);
  await tester.ensureVisible(find.text('Ver experiencia e insignias'));
  await tester.tap(find.text('Ver experiencia e insignias'));
  await settle(tester, frames: 10);
}

final _withData = GamificationProfile(
  xp: 295,
  level: 2,
  nextLevelXp: 400,
  missingXp: 105,
  progressPct: 47.5,
  badges: [
    BadgeProgress(
      id: 1,
      name: 'Primer paso',
      criterion: 'Cumple tu primer reto',
      xpReward: 20,
      earned: true,
      earnedAt: DateTime(2026, 10, 21),
    ),
    const BadgeProgress(
      id: 2,
      name: 'Constancia',
      criterion: 'Inicia sesión 7 días seguidos',
      xpReward: 50,
      earned: false,
    ),
  ],
  history: [
    for (var i = 1; i <= 8; i++) XpMovement(reason: 'Reto $i', amount: 10 * i),
  ],
);

void main() {
  testWidgets('sin puntos ni insignias muestra el estado vacío', (
    tester,
  ) async {
    final repo = FakeGamificationRepository(
      profile: const GamificationProfile(
        xp: 0,
        level: 0,
        nextLevelXp: 200,
        missingXp: 200,
        progressPct: 0,
      ),
    );
    await _openXpScreen(tester, _world(repo));

    expect(find.text('Experiencia e insignias'), findsOneWidget);
    expect(find.text('Aún no tienes puntos ni insignias.'), findsOneWidget);
    expect(
      find.text('Todavía no hay insignias en el catálogo.'),
      findsOneWidget,
    );
    expect(find.text('Todavía no tienes movimientos de XP.'), findsOneWidget);
  });

  testWidgets('el Perfil enlaza a la pantalla con XP, insignias e historial '
      'completo', (tester) async {
    await _openXpScreen(
      tester,
      _world(FakeGamificationRepository(profile: _withData)),
    );

    expect(find.text('295 XP · Nivel 2'), findsOneWidget);
    expect(find.text('Insignias · 1 de 2'), findsOneWidget);
    expect(find.text('Primer paso'), findsOneWidget);
    expect(find.text('Constancia'), findsOneWidget);
    // El historial no se recorta a 5 movimientos.
    expect(find.text('Reto 8', skipOffstage: false), findsOneWidget);
  });

  testWidgets('tocar una insignia muestra criterio, XP y fecha', (
    tester,
  ) async {
    await _openXpScreen(
      tester,
      _world(FakeGamificationRepository(profile: _withData)),
    );

    await tester.tap(find.text('Primer paso'));
    await settle(tester);
    expect(find.text('Cumple tu primer reto'), findsOneWidget);
    expect(find.text('Recompensa: +20 XP'), findsOneWidget);
    expect(find.textContaining('Obtenida · '), findsOneWidget);
  });

  testWidgets('una insignia bloqueada indica que aún no se obtiene', (
    tester,
  ) async {
    await _openXpScreen(
      tester,
      _world(FakeGamificationRepository(profile: _withData)),
    );

    await tester.tap(find.text('Constancia'));
    await settle(tester);
    expect(find.text('Aún no la obtienes.'), findsOneWidget);
  });

  testWidgets('si falla la carga en el Perfil, avisa y permite reintentar', (
    tester,
  ) async {
    final repo = FakeGamificationRepository(
      profile: _withData,
      profileFailure: const NetworkFailure(),
    );
    await _openProfile(tester, _world(repo));

    expect(
      find.text('No se pudo conectar con el servidor. Revisa tu conexión.'),
      findsOneWidget,
    );

    repo.profileFailure = null;
    await tester.tap(find.text('Reintentar'));
    await settle(tester, frames: 10);
    expect(find.text('295 XP · Nivel 2'), findsOneWidget);
  });
}
