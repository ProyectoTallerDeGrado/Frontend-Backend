import 'package:app_emprendeu/core/error/failure.dart';
import 'package:app_emprendeu/core/error/result.dart';
import 'package:app_emprendeu/features/ai_assistant/domain/entities/chat_message.dart';
import 'package:app_emprendeu/features/ai_assistant/domain/entities/knowledge_match.dart';
import 'package:app_emprendeu/features/ai_assistant/domain/entities/local_knowledge_status.dart';
import 'package:app_emprendeu/features/ai_assistant/domain/usecases/local_coach_usecases.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_local_coach.dart';
import 'fake_own_documents.dart';

const _costos = KnowledgeMatch(
  text: 'Separa costos fijos y variables.',
  documentId: 1,
  title: 'Guía de costos',
  score: 0.8,
);
const _costos2 = KnowledgeMatch(
  text: 'Con los costos estimas el punto de equilibrio.',
  documentId: 1,
  title: 'Guía de costos',
  score: 0.7,
);
const _lejano = KnowledgeMatch(
  text: 'Receta de pasta.',
  documentId: 2,
  title: 'Recetario',
  score: 0.2,
);

void main() {
  late FakeLocalKnowledgeRepository knowledge;
  late FakeLocalCoachRepository coach;
  late AskLocalCoachUseCase ask;

  setUp(() {
    knowledge = FakeLocalKnowledgeRepository(
      current: const LocalKnowledgeStatus(documents: 2, fragments: 10),
    );
    coach = FakeLocalCoachRepository(answer: 'Haz una tabla de costos.');
    ask = AskLocalCoachUseCase(
      knowledge,
      coach,
      clock: () => DateTime.utc(2026, 11, 14),
    );
  });

  Future<LocalCoachAnswer> ok(
    String q, [
    List<ChatMessage> history = const [],
  ]) async {
    final r = await ask(q, history: history, onPartial: (_) {});
    return r.valueOrNull!;
  }

  test('sin fragmentos relevantes no inventa ni llama al modelo', () async {
    knowledge.matches = [_lejano]; // por debajo del umbral
    final a = await ok('¿Cómo calculo mis costos?');
    expect(a.answer.text, localCoachFallback);
    expect(a.answer.sources, isEmpty);
    expect(a.answer.suggestMentor, isTrue);
    expect(coach.generateCalls, 0);
  });

  test(
    'con contexto responde, cita el documento una vez y lo guarda',
    () async {
      knowledge.matches = [_costos, _costos2, _lejano];
      final partials = <String>[];
      final r = await ask(
        '¿Cómo calculo mis costos?',
        history: const [],
        onPartial: partials.add,
      );
      final a = r.valueOrNull!;
      expect(a.answer.text, 'Haz una tabla de costos.');
      expect(a.answer.sources, ['Guía de costos']);
      expect(a.answer.suggestMentor, isFalse);
      expect(partials.last, 'Haz una tabla de costos.');
      // el contexto lleva los fragmentos relevantes y no el lejano
      expect(
        coach.lastPrompt,
        contains('[CIE-U: Guía de costos] Separa costos fijos'),
      );
      expect(coach.lastPrompt, isNot(contains('Receta de pasta')));
      expect(coach.stored.map((m) => m.text), [
        '¿Cómo calculo mis costos?',
        'Haz una tabla de costos.',
      ]);
    },
  );

  test(
    'temas financieros o legales sugieren mentor aunque haya fuente',
    () async {
      knowledge.matches = [_costos];
      final a = await ok('Necesito un crédito para mis costos');
      expect(a.answer.sources, isNotEmpty);
      expect(a.answer.suggestMentor, isTrue);
    },
  );

  test('el prompt incluye los últimos turnos de la conversación', () async {
    knowledge.matches = [_costos];
    const history = [
      ChatMessage(id: 1, isUser: true, text: 'Vendo café'),
      ChatMessage(id: 2, isUser: false, text: 'Bien, cuéntame más'),
    ];
    await ok('¿Y mis costos?', history);
    expect(coach.lastPrompt, contains('Emprendedor: Vendo café'));
    expect(coach.lastPrompt, contains('Coach: Bien, cuéntame más'));
    expect(coach.lastPrompt, endsWith('Pregunta: ¿Y mis costos?'));
    expect(coach.stored, hasLength(4));
  });

  test(
    'sin ninguna guía en el celular lo explica sin llamar al modelo',
    () async {
      knowledge.current = LocalKnowledgeStatus.empty;
      final a = await ok('¿Cómo calculo mis costos?');
      expect(a.answer.text, localCoachNoDocuments);
      expect(a.answer.suggestMentor, isTrue);
      expect(coach.generateCalls, 0);
    },
  );

  test('un saludo lo responde el modelo sin documentos ni mentor', () async {
    knowledge.current = LocalKnowledgeStatus.empty;
    coach.answer = '¡Hola! ¿En qué te ayudo?';
    final a = await ok('Hola');
    expect(coach.generateCalls, 1);
    expect(coach.lastPrompt, isNot(contains('Contexto:\n[')));
    expect(a.answer.text, '¡Hola! ¿En qué te ayudo?');
    expect(a.answer.sources, isEmpty);
    expect(a.answer.suggestMentor, isFalse);
    expect(coach.stored, hasLength(2));
  });

  test('reconoce saludos y charla corta, pero no preguntas reales', () {
    for (final t in [
      'hola',
      '¡Hola!',
      'Buenas tardes coach',
      'hola, ¿qué puedes hacer?',
      'Muchas gracias',
      'ok',
    ]) {
      expect(isSmallTalk(t), isTrue, reason: t);
    }
    for (final t in [
      'Hola, ¿cómo calculo mis costos?',
      '¿Qué es un modelo de negocio?',
      'costos',
    ]) {
      expect(isSmallTalk(t), isFalse, reason: t);
    }
  });

  test('valida el texto antes de buscar', () async {
    final r = await ask('   ', history: const [], onPartial: (_) {});
    expect(r.failureOrNull, isA<FieldFailure>());
  });

  test('si el modelo falla devuelve el fallo y no guarda nada', () async {
    knowledge.matches = [_costos];
    coach.failure = const LocalAiFailure('sin memoria');
    final r = await ask('¿Costos?', history: const [], onPartial: (_) {});
    expect(r, isA<Err<LocalCoachAnswer>>());
    expect(coach.stored, isEmpty);
  });

  group('con archivos propios', () {
    const plan = KnowledgeMatch(
      text: 'Mi plan: vender café en ferias.',
      documentId: 9,
      title: 'plan.pdf',
      score: 0.9,
      own: true,
    );

    test('mezcla sus archivos con las guías y los distingue', () async {
      knowledge.matches = [_costos];
      final own = FakeOwnDocumentsRepository(matches: const [plan]);
      final withOwn = AskLocalCoachUseCase(knowledge, coach, own: own);
      final r = await withOwn(
        '¿Qué mejorarías de mi plan?',
        history: const [],
        onPartial: (_) {},
      );
      final a = r.valueOrNull!.answer;
      expect(coach.lastPrompt, contains('[Tu archivo: plan.pdf] Mi plan'));
      expect(coach.lastPrompt, contains('[CIE-U: Guía de costos]'));
      expect(a.sources, ['Tu archivo: plan.pdf', 'Guía de costos']);
      expect(a.suggestMentor, isFalse);
    });

    test('solo con sus archivos responde, pero sugiere un mentor', () async {
      final own = FakeOwnDocumentsRepository(matches: const [plan]);
      final withOwn = AskLocalCoachUseCase(knowledge, coach, own: own);
      final r = await withOwn(
        'Resume mi plan',
        history: const [],
        onPartial: (_) {},
      );
      final a = r.valueOrNull!.answer;
      expect(coach.generateCalls, 1);
      expect(a.sources, ['Tu archivo: plan.pdf']);
      expect(a.suggestMentor, isTrue); // sin una guía del CIE-U que lo respalde
    });
  });
}
