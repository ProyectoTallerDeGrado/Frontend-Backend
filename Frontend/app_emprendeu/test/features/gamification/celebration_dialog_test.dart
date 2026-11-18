import 'package:app_emprendeu/app/theme/app_theme.dart';
import 'package:app_emprendeu/features/gamification/domain/entities/completion_result.dart';
import 'package:app_emprendeu/features/gamification/presentation/widgets/celebration_dialog.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _open(WidgetTester tester, CompletionResult result) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(useGoogleFonts: false),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showCelebration(context, result),
            child: const Text('abrir'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('subir de nivel muestra el nivel, el XP y la insignia', (
    tester,
  ) async {
    await _open(
      tester,
      const CompletionResult(
        challengeId: 1,
        xpAwarded: 150,
        xpTotal: 400,
        level: 3,
        leveledUp: true,
        newBadges: ['Primer cliente'],
      ),
    );

    expect(find.text('¡Subiste al nivel 3!'), findsOneWidget);
    expect(find.textContaining('Sumaste 150 XP'), findsOneWidget);
    expect(find.text('Primer cliente'), findsOneWidget);

    await tester.tap(find.text('Seguir mi camino'));
    await tester.pumpAndSettle();
    expect(find.text('¡Subiste al nivel 3!'), findsNothing);
  });

  testWidgets('una insignia sin subir de nivel se anuncia como insignia', (
    tester,
  ) async {
    await _open(
      tester,
      const CompletionResult(
        challengeId: 1,
        xpAwarded: 50,
        xpTotal: 120,
        level: 1,
        leveledUp: false,
        newBadges: ['Constancia'],
      ),
    );

    expect(find.text('¡Nueva insignia!'), findsOneWidget);
    expect(find.text('Constancia'), findsOneWidget);
  });
}
