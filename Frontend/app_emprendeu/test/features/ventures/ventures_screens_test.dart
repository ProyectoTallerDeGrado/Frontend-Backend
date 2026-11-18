import 'package:app_emprendeu/core/error/failure.dart';
import 'package:app_emprendeu/features/documents/domain/entities/picked_file.dart';
import 'package:app_emprendeu/features/gamification/domain/entities/gamification_profile.dart';
import 'package:app_emprendeu/features/ventures/domain/entities/milestone.dart';
import 'package:app_emprendeu/features/ventures/domain/entities/venture.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';
import '../../support/test_app.dart';
import '../auth/fake_auth_repository.dart';
import '../documents/fake_documents.dart';

const _venture = Venture(
  id: 1,
  name: 'Sabores del Oriente',
  stageName: 'Incubación',
  sector: 'Alimentos',
  status: 'activo',
);

Future<void> _openPerfil(WidgetTester tester, TestWorld world) async {
  await pumpApp(tester, world);
  await tester.tap(find.text('Perfil'));
  await settle(tester);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 200));
  await tester.tap(finder);
  await settle(tester);
}

TestWorld _world({
  FakeVenturesRepository? ventures,
  FakeDocumentsRepository? documents,
  FakeEvidencePicker? picker,
  GamificationProfile? profile,
}) => TestWorld(
  auth: FakeAuthRepository(token: 'tok-1'),
  ventures: ventures ?? FakeVenturesRepository(venture: _venture),
  documents: documents,
  picker: picker,
  gamification: FakeGamificationRepository(profile: profile),
);

void main() {
  testWidgets('CU08: el Perfil muestra XP, nivel e insignias obtenidas', (
    tester,
  ) async {
    await _openPerfil(
      tester,
      _world(
        profile: GamificationProfile(
          xp: 295,
          level: 2,
          nextLevelXp: 400,
          missingXp: 105,
          progressPct: 47.5,
          badges: [
            BadgeProgress(
              id: 1,
              name: 'Primer paso',
              xpReward: 20,
              earned: true,
              earnedAt: DateTime(2030, 1, 2),
            ),
            const BadgeProgress(
              id: 2,
              name: 'Constancia',
              xpReward: 50,
              earned: false,
            ),
          ],
          history: const [XpMovement(reason: 'Reto: Propuesta', amount: 75)],
        ),
      ),
    );
    final scroll = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('295 XP · Nivel 2'),
      200,
      scrollable: scroll,
    );
    expect(find.text('295 XP · Nivel 2'), findsOneWidget);
    expect(find.text('Te faltan 105 XP para el nivel 3.'), findsOneWidget);
    expect(find.text('Insignias · 1 de 2'), findsOneWidget);
    // El detalle (insignias y movimientos) vive en la pantalla `/xp`.
    expect(find.text('Ver experiencia e insignias'), findsOneWidget);
  });

  testWidgets(
    'CU05: el Perfil muestra el equipo y, con varios emprendimientos, permite elegir',
    (tester) async {
      const team = [
        VentureMember(entrepreneurId: 7, name: 'Rosa Quispe', role: 'fundador'),
        VentureMember(
          entrepreneurId: 8,
          name: 'Luis Mamani',
          role: 'cofundador',
        ),
      ];
      final gamification = FakeGamificationRepository();
      final ventures = FakeVenturesRepository(
        ventures: const [
          Venture(
            id: 1,
            name: 'Sabores del Oriente',
            stageName: 'Incubación',
            members: team,
          ),
          Venture(id: 2, name: 'Café de altura', stageName: 'Preincubación'),
        ],
      );
      await _openPerfil(
        tester,
        TestWorld(
          auth: FakeAuthRepository(token: 'tok-1'),
          ventures: ventures,
          gamification: gamification,
        ),
      );

      // equipo en solo lectura
      expect(find.text('Equipo'), findsOneWidget);
      expect(find.text('Rosa Quispe'), findsOneWidget);
      expect(find.text('Cofundador'), findsOneWidget);

      // elegir el segundo emprendimiento
      await _tap(tester, find.byType(DropdownButtonFormField<int>));
      await tester.tap(find.text('Café de altura').last);
      await settle(tester);
      expect(find.text('Preincubación'), findsOneWidget);
      expect(find.text('Rosa Quispe'), findsNothing);

      // Inicio y Camino piden los datos del emprendimiento elegido
      await tester.tap(find.text('Inicio'));
      await settle(tester);
      expect(gamification.lastVentureId, 2);
    },
  );

  testWidgets('CU05: con un solo emprendimiento no aparece el selector', (
    tester,
  ) async {
    await _openPerfil(tester, _world());
    expect(find.byType(DropdownButtonFormField<int>), findsNothing);
  });

  testWidgets('CU05: edita el emprendimiento propio y guarda', (tester) async {
    final ventures = FakeVenturesRepository(venture: _venture);
    await _openPerfil(tester, _world(ventures: ventures));
    expect(find.text('Sabores del Oriente'), findsOneWidget);
    expect(find.text('Incubación · Alimentos'), findsOneWidget);

    await _tap(tester, find.text('Editar emprendimiento'));
    await tester.enterText(find.byType(TextField).at(0), 'Sabores del Valle');
    await tester.enterText(find.byType(TextField).at(2), 'Platos típicos');
    await _tap(tester, find.text('Guardar cambios'));

    expect(ventures.updateCalls, 1);
    expect(ventures.lastUpdatedName, 'Sabores del Valle');
    expect(ventures.lastUpdatedDescription, 'Platos típicos');
    // volvió al Perfil con los datos nuevos
    expect(find.text('Sabores del Valle'), findsOneWidget);
  });

  testWidgets('CU05: el nombre vacío se marca y no guarda', (tester) async {
    final ventures = FakeVenturesRepository(venture: _venture);
    await _openPerfil(tester, _world(ventures: ventures));
    await _tap(tester, find.text('Editar emprendimiento'));
    await tester.enterText(find.byType(TextField).at(0), '   ');
    await _tap(tester, find.text('Guardar cambios'));
    expect(
      find.text('Ingresa el nombre de tu emprendimiento.'),
      findsOneWidget,
    );
    expect(ventures.updateCalls, 0);
  });

  testWidgets('CU20: registra un hito con evidencia', (tester) async {
    final ventures = FakeVenturesRepository(venture: _venture);
    final documents = FakeDocumentsRepository();
    await _openPerfil(tester, _world(ventures: ventures, documents: documents));
    await _tap(tester, find.text('Hitos y evidencia'));
    expect(find.text('Todavía no registraste hitos.'), findsOneWidget);

    await _tap(tester, find.text('Registrar hito'));
    await tester.enterText(find.byType(TextField).at(0), 'Primer prototipo');
    await _tap(tester, find.text('Adjuntar evidencia (opcional)'));
    expect(find.text('Evidencia: prototipo.pdf'), findsOneWidget);
    await _tap(tester, find.text('Guardar hito'));

    expect(ventures.milestoneCalls, 1);
    expect(documents.uploadCalls, 1);
    expect(
      documents.lastMilestoneId,
      51,
    ); // la evidencia cuelga del hito recién creado
    expect(documents.lastVentureId, 1);
    expect(find.text('Primer prototipo'), findsOneWidget);
    expect(find.text('prototipo.pdf'), findsOneWidget);
  });

  testWidgets(
    'CU20: si la evidencia falla, el hito queda guardado y se avisa',
    (tester) async {
      final ventures = FakeVenturesRepository(venture: _venture);
      final documents = FakeDocumentsRepository(
        uploadFailure: const FieldFailure(
          'file',
          'El archivo es demasiado grande.',
        ),
      );
      await _openPerfil(
        tester,
        _world(ventures: ventures, documents: documents),
      );
      await _tap(tester, find.text('Hitos y evidencia'));
      await _tap(tester, find.text('Registrar hito'));
      await tester.enterText(find.byType(TextField).at(0), 'Lancé la tienda');
      await _tap(tester, find.text('Adjuntar evidencia (opcional)'));
      await _tap(tester, find.text('Guardar hito'));

      expect(ventures.milestones.length, 1); // el hito sí se guardó
      expect(documents.files, isEmpty);
      expect(
        find.textContaining('no se pudo subir la evidencia'),
        findsOneWidget,
      );
      expect(find.text('Lancé la tienda'), findsOneWidget);
    },
  );

  testWidgets('CU20: hito sin evidencia, adjuntar después y marcar cumplido', (
    tester,
  ) async {
    final ventures = FakeVenturesRepository(
      venture: _venture,
      milestones: [
        const Milestone(id: 9, title: 'Registro de marca', done: false),
      ],
    );
    final documents = FakeDocumentsRepository();
    final picker = FakeEvidencePicker(
      file: const PickedFile(name: 'registro.png', path: '/tmp/registro.png'),
    );
    await _openPerfil(
      tester,
      _world(ventures: ventures, documents: documents, picker: picker),
    );
    await _tap(tester, find.text('Hitos y evidencia'));
    expect(find.text('Pendiente'), findsOneWidget);

    await _tap(tester, find.text('Adjuntar evidencia'));
    expect(documents.lastMilestoneId, 9);
    expect(find.text('registro.png'), findsOneWidget);

    await _tap(tester, find.text('Marcar cumplido'));
    expect(ventures.milestones.single.done, true);
    expect(find.text('Marcar cumplido'), findsNothing);

    // cancelar el selector no sube nada
    picker.file = null;
    await _tap(tester, find.text('Adjuntar evidencia'));
    expect(documents.uploadCalls, 1);
  });
}
