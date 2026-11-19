import 'package:app_emprendeu/core/error/result.dart';
import 'package:app_emprendeu/features/auth/data/models/auth_user_dto.dart';
import 'package:app_emprendeu/features/auth/domain/entities/auth_user.dart';
import 'package:app_emprendeu/features/auth/presentation/tour/tour_steps.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_app.dart';
import '../fake_auth_repository.dart';

const _newcomer = AuthUser(
  id: 7,
  nombre: 'Camila',
  apellido: 'Justiniano',
  email: 'camila@correo.com',
  rol: 'emprendedor',
);

void main() {
  test('los pasos cubren las cinco pestañas y empiezan y acaban en Inicio', () {
    final steps = buildTourSteps(firstName: 'Camila');
    expect(steps.first.tab, TourTab.home);
    expect(steps.first.title, '¡Hola, Camila!');
    expect(steps.last.tab, TourTab.home);
    expect(steps.map((s) => s.tab).toSet(), {0, 1, 2, 3, 4});
    expect(steps.map((s) => s.id).toSet().length, steps.length);
  });

  test('el DTO lee tutorial_completado_at, con y sin valor', () {
    const base = {
      'usuario_id': 1,
      'nombre': 'A',
      'apellido': 'B',
      'email': 'a@b.c',
      'rol': 'emprendedor',
    };
    expect(AuthUserDto.fromJson(base).toEntity().hasSeenTutorial, isFalse);
    final seen = AuthUserDto.fromJson({
      ...base,
      'tutorial_completado_at': '2026-05-01T10:00:00Z',
    });
    expect(seen.toEntity().hasSeenTutorial, isTrue);
  });

  testWidgets('un usuario nuevo ve el tutorial, avanza y al saltar lo guarda', (
    tester,
  ) async {
    final repo = FakeAuthRepository(
      token: 'tok-1',
      meResult: const Result.ok(_newcomer),
    );
    await pumpApp(tester, TestWorld(auth: repo));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('¡Hola, Camila!'), findsNothing);
    expect(find.text('¡Bienvenido a EmprendeU!'), findsOneWidget);

    await tester.tap(find.text('Siguiente'));
    await tester.pump();
    expect(find.text('Tu barra de navegación'), findsOneWidget);

    await tester.tap(find.text('Saltar'));
    await tester.pump();
    expect(find.text('Tu barra de navegación'), findsNothing);
    expect(repo.setTutorialCalls, 1);
    expect(repo.lastTutorialCompleted, isTrue);
    // Deja que termine el sondeo pendiente del paso que se abandonó.
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('quien ya lo vio no lo ve de nuevo', (tester) async {
    final repo = FakeAuthRepositoryWithToken();
    await pumpApp(tester, TestWorld(auth: repo));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Saltar'), findsNothing);
    expect(repo.setTutorialCalls, 0);
  });
}
