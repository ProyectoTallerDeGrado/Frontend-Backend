import 'package:app_emprendeu/core/error/failure.dart';
import 'package:app_emprendeu/features/ai_assistant/domain/usecases/assistant_usecases.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_assistant_repository.dart';

void main() {
  group('AskCoachUseCase (CU11)', () {
    test('no envía un mensaje vacío', () async {
      final repo = FakeAssistantRepository();
      final result = await AskCoachUseCase(repo)('   ');
      expect(result.failureOrNull, isA<FieldFailure>());
      expect(repo.askCalls, 0);
    });

    test('no envía un mensaje demasiado largo', () async {
      final repo = FakeAssistantRepository();
      final result = await AskCoachUseCase(repo)(
        'a' * (maxCoachMessageLength + 1),
      );
      expect(result.failureOrNull, isA<FieldFailure>());
      expect(repo.askCalls, 0);
    });

    test(
      'envía el texto sin espacios sobrantes y respeta la conversación',
      () async {
        final repo = FakeAssistantRepository();
        final result = await AskCoachUseCase(repo)(
          '  ¿Cómo calculo mis costos?  ',
          conversationId: 5,
        );
        expect(result.valueOrNull?.conversationId, 5);
        expect(repo.lastMessage, '¿Cómo calculo mis costos?');
        expect(repo.lastConversationId, 5);
      },
    );

    test('si el servicio de IA no responde, devuelve el fallo claro', () async {
      final repo = FakeAssistantRepository(
        failure: const AssistantUnavailableFailure(),
      );
      final result = await AskCoachUseCase(repo)('hola');
      expect(result.failureOrNull, isA<AssistantUnavailableFailure>());
      expect(result.failureOrNull?.message, contains('Tu mensaje no se envió'));
    });
  });
}
