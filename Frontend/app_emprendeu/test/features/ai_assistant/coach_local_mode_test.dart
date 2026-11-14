import 'package:app_emprendeu/features/ai_assistant/domain/entities/chat_message.dart';
import 'package:app_emprendeu/features/ai_assistant/domain/entities/knowledge_match.dart';
import 'package:app_emprendeu/features/ai_assistant/domain/entities/local_ai_status.dart';
import 'package:app_emprendeu/features/ai_assistant/domain/entities/local_knowledge_status.dart';
import 'package:app_emprendeu/features/ai_assistant/domain/usecases/local_coach_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';
import '../auth/fake_auth_repository.dart';
import 'fake_assistant_repository.dart';
import 'fake_local_ai_repository.dart';
import 'fake_local_coach.dart';

const _match = KnowledgeMatch(
  text: 'Separa costos fijos y variables.',
  documentId: 1,
  title: 'Guía de costos',
  score: 0.9,
);

Future<TestWorld> _openCoach(
  WidgetTester tester, {
  FakeLocalKnowledgeRepository? knowledge,
  FakeLocalCoachRepository? coach,
  FakeAssistantRepository? assistant,
}) async {
  final world = TestWorld(
    auth: FakeAuthRepository(token: 'tok-1'),
    localAi: FakeLocalAiRepository(current: LocalAiStatus.installed),
    localKnowledge:
        knowledge ??
        FakeLocalKnowledgeRepository(
          matches: const [_match],
          current: const LocalKnowledgeStatus(documents: 3, fragments: 20),
        ),
    localCoach: coach,
    assistant: assistant,
  );
  await pumpApp(tester, world);
  await tester.tap(find.text('Coach'));
  await settle(tester);
  return world;
}

Future<void> _ask(WidgetTester tester, String question) async {
  await tester.enterText(find.byType(TextField), question);
  await tester.pump();
  await tester.tap(find.byTooltip('Enviar'));
  await settle(tester);
}

void main() {
  testWidgets('con la IA instalada responde en el celular con sus fuentes', (
    tester,
  ) async {
    final world = await _openCoach(
      tester,
      coach: FakeLocalCoachRepository(answer: 'Haz una tabla de costos.'),
    );
    expect(find.text('Responde en tu celular, sin internet.'), findsOneWidget);
    expect(find.text('En tu celular'), findsOneWidget);
    // las conversaciones anteriores son del servidor: no se ofrecen aquí
    expect(find.byTooltip('Conversaciones anteriores'), findsNothing);
    // al abrir el Coach se buscan documentos nuevos
    expect(world.localKnowledge.syncCalls, 1);
    expect(find.text('3 documentos del CIE-U en tu celular'), findsOneWidget);

    await _ask(tester, '¿Cómo calculo mis costos?');
    expect(find.text('Haz una tabla de costos.'), findsOneWidget);
    expect(find.text('Fuentes: Guía de costos'), findsOneWidget);
    expect(world.assistant.askCalls, 0); // no pasó por el servidor
    expect(world.localCoach.stored, hasLength(2));
  });

  testWidgets('sin información suficiente sugiere un mentor', (tester) async {
    final world = await _openCoach(
      tester,
      knowledge: FakeLocalKnowledgeRepository(),
    );
    await _ask(tester, 'Receta de pasta');
    expect(find.text(localCoachFallback), findsOneWidget);
    expect(find.text('Agendar una mentoría'), findsOneWidget);
    expect(world.localCoach.generateCalls, 0);
  });

  testWidgets('reabre la conversación guardada en el celular', (tester) async {
    final coach = FakeLocalCoachRepository()
      ..stored = const [
        ChatMessage(id: 1, isUser: true, text: 'Hola coach'),
        ChatMessage(id: 2, isUser: false, text: 'Hola, ¿en qué te ayudo?'),
      ];
    await _openCoach(tester, coach: coach);
    expect(find.text('Hola, ¿en qué te ayudo?'), findsOneWidget);

    await tester.tap(find.byTooltip('Nueva conversación'));
    await settle(tester);
    expect(find.text('Hazme una pregunta'), findsOneWidget);
    expect(coach.stored, isEmpty);
  });

  testWidgets('se puede cambiar al coach en línea', (tester) async {
    final world = await _openCoach(tester);
    await tester.tap(find.text('En línea'));
    await settle(tester);
    expect(find.text('Responde con la información del CIE-U.'), findsOneWidget);
    expect(find.byTooltip('Conversaciones anteriores'), findsOneWidget);
    await _ask(tester, '¿Cómo calculo mis costos?');
    expect(world.assistant.askCalls, 1);
    expect(world.localCoach.generateCalls, 0);
  });
}
