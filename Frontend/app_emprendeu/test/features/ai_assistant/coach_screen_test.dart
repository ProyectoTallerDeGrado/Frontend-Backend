import 'package:app_emprendeu/core/error/failure.dart';
import 'package:app_emprendeu/features/ai_assistant/domain/entities/chat_message.dart';
import 'package:app_emprendeu/features/ai_assistant/domain/entities/coach_conversation.dart';
import 'package:app_emprendeu/features/ai_assistant/domain/entities/conversation_summary.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_app.dart';
import '../auth/fake_auth_repository.dart';
import 'fake_assistant_repository.dart';

Future<void> _openCoach(
  WidgetTester tester,
  FakeAssistantRepository assistant,
) async {
  await pumpApp(
    tester,
    TestWorld(
      auth: FakeAuthRepository(token: 'tok-1'),
      assistant: assistant,
    ),
  );
  await tester.tap(find.text('Coach'));
  await settle(tester);
}

Future<void> _ask(WidgetTester tester, String question) async {
  await tester.enterText(find.byType(TextField), question);
  await tester.pump();
  await tester.tap(find.byTooltip('Enviar'));
  await settle(tester);
}

void main() {
  testWidgets('sin conversaciones previas muestra la invitación a preguntar', (
    tester,
  ) async {
    await _openCoach(tester, FakeAssistantRepository());
    expect(find.text('Hazme una pregunta'), findsOneWidget);
    expect(find.text('¿Cómo calculo mis costos?'), findsOneWidget);
    // sin texto, enviar está desactivado
    final send = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.send),
    );
    expect(send.onPressed, isNull);
  });

  testWidgets('pregunta, respuesta con sus fuentes y conversación continuada', (
    tester,
  ) async {
    final assistant = FakeAssistantRepository();
    await _openCoach(tester, assistant);
    await _ask(tester, '¿Cómo calculo mis costos?');

    expect(find.text('¿Cómo calculo mis costos?'), findsOneWidget);
    expect(find.text('Separa costos fijos y variables.'), findsOneWidget);
    expect(find.text('Fuentes: Guía de costos'), findsOneWidget);
    expect(
      assistant.lastConversationId,
      isNull,
    ); // la primera abre la conversación

    await _ask(tester, 'Y mis ventas?');
    expect(assistant.lastConversationId, 77); // la segunda sigue en la misma
    expect(find.text('Y mis ventas?'), findsOneWidget);
  });

  testWidgets('una sugerencia rápida se envía como pregunta', (tester) async {
    final assistant = FakeAssistantRepository();
    await _openCoach(tester, assistant);
    await tester.tap(find.text('¿Qué es un modelo de negocio?'));
    await settle(tester);
    expect(assistant.lastMessage, '¿Qué es un modelo de negocio?');
  });

  testWidgets('sin información suficiente sugiere hablar con un mentor', (
    tester,
  ) async {
    final assistant = FakeAssistantRepository(
      answer: 'No encontré información suficiente en la base documental del CIE-U para responder con certeza.',
      sources: const [],
      suggestMentor: true,
    );
    await _openCoach(tester, assistant);
    await _ask(tester, 'Receta de pasta');

    expect(
      find.textContaining('No encontré información suficiente'),
      findsOneWidget,
    );
    expect(find.textContaining('Fuentes:'), findsNothing);
    await tester.tap(find.text('Agendar una mentoría'));
    await settle(tester);
    // lleva a la pestaña Mentorías
    expect(
      find.text('Tus sesiones con el asesor que acompaña a tu emprendimiento.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'si el servicio de IA no responde: error claro y el texto vuelve al campo',
    (tester) async {
      final assistant = FakeAssistantRepository(
        failure: const AssistantUnavailableFailure(),
      );
      await _openCoach(tester, assistant);
      await _ask(tester, '¿Cómo calculo mis costos?');

      expect(
        find.textContaining('El coach no está disponible'),
        findsOneWidget,
      );
      // nada quedó en el chat a medias: se ve la invitación y el texto para reenviar
      expect(find.text('Hazme una pregunta'), findsOneWidget);
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller?.text, '¿Cómo calculo mis costos?');

      // al volver el servicio, el mismo texto se reenvía y el aviso desaparece
      assistant.failure = null;
      await tester.tap(find.byTooltip('Enviar'));
      await settle(tester);
      expect(find.textContaining('El coach no está disponible'), findsNothing);
      expect(find.text('Separa costos fijos y variables.'), findsOneWidget);
    },
  );

  testWidgets('abre con la conversación anterior y permite empezar una nueva', (
    tester,
  ) async {
    final assistant = FakeAssistantRepository(
      conversation: const CoachConversation(
        id: 9,
        messages: [
          ChatMessage(id: 1, isUser: true, text: 'Hola coach'),
          ChatMessage(id: 2, isUser: false, text: 'Hola, ¿en qué te ayudo?'),
        ],
      ),
    );
    await _openCoach(tester, assistant);
    expect(find.text('Hola coach'), findsOneWidget);
    expect(find.text('Hola, ¿en qué te ayudo?'), findsOneWidget);

    await _ask(tester, 'Otra duda');
    expect(assistant.lastConversationId, 9);

    await tester.tap(find.byTooltip('Nueva conversación'));
    await settle(tester);
    expect(find.text('Hazme una pregunta'), findsOneWidget);
    await _ask(tester, 'Tema distinto');
    expect(assistant.lastConversationId, isNull);
  });

  group('CU11: conversaciones anteriores', () {
    final older = CoachConversation(
      id: 5,
      messages: const [
        ChatMessage(id: 1, isUser: true, text: '¿Cómo valido mi idea?'),
        ChatMessage(id: 2, isUser: false, text: 'Habla con 10 clientes.'),
      ],
    );
    final latest = CoachConversation(
      id: 9,
      messages: const [
        ChatMessage(id: 3, isUser: true, text: 'Costos fijos'),
        ChatMessage(id: 4, isUser: false, text: 'Son los que no cambian.'),
      ],
    );

    FakeAssistantRepository twoConversations() =>
        FakeAssistantRepository(conversation: latest)
          ..byId = {5: older, 9: latest}
          ..summaries = [
            ConversationSummary(
              id: 9,
              messageCount: 2,
              startedAt: DateTime.utc(2030, 1, 15, 13),
            ),
            ConversationSummary(
              id: 5,
              messageCount: 2,
              startedAt: DateTime.utc(2030, 1, 10, 13),
            ),
          ];

    testWidgets('lista las conversaciones y reabre una anterior', (
      tester,
    ) async {
      final assistant = twoConversations();
      await _openCoach(tester, assistant);
      expect(find.text('Son los que no cambian.'), findsOneWidget);

      await tester.tap(find.byTooltip('Conversaciones anteriores'));
      await settle(tester);
      expect(find.text('Conversaciones'), findsOneWidget);
      expect(find.text('2 mensajes · abierta'), findsOneWidget);

      // la más antigua
      await tester.tap(find.text('2 mensajes').last);
      await settle(tester);
      expect(assistant.lastOpenedId, 5);
      expect(find.text('Habla con 10 clientes.'), findsOneWidget);
      expect(find.text('Son los que no cambian.'), findsNothing);
    });

    testWidgets('al continuar la conversación reabierta se usa su id', (
      tester,
    ) async {
      final assistant = twoConversations();
      await _openCoach(tester, assistant);
      await tester.tap(find.byTooltip('Conversaciones anteriores'));
      await settle(tester);
      await tester.tap(find.text('2 mensajes').last);
      await settle(tester);

      await _ask(tester, 'Y si no tengo clientes aún');
      expect(assistant.lastConversationId, 5);
    });

    testWidgets('sin conversaciones lo dice', (tester) async {
      await _openCoach(tester, FakeAssistantRepository());
      await tester.tap(find.byTooltip('Conversaciones anteriores'));
      await settle(tester);
      expect(find.text('Todavía no has hablado con el coach.'), findsOneWidget);
    });

    testWidgets('si no carga, ofrece reintentar', (tester) async {
      final assistant = twoConversations();
      await _openCoach(tester, assistant);
      assistant.failure = const NetworkFailure();
      await tester.tap(find.byTooltip('Conversaciones anteriores'));
      await settle(tester);
      expect(find.text('Reintentar'), findsOneWidget);
    });
  });
}
