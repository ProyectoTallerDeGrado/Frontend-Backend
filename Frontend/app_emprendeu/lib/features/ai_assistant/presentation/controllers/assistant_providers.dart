import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/conversation_summary.dart';
import '../../domain/repositories/assistant_repository.dart';
import '../../domain/usecases/assistant_usecases.dart';
import '../../../auth/index.dart';
import '../../../ventures/index.dart';
import 'local_coach_providers.dart';

/// Contrato del repositorio; la implementación se inyecta en `app/providers.dart`.
final assistantRepositoryProvider = Provider<AssistantRepository>(
  (ref) => throw UnimplementedError(
    'assistantRepositoryProvider sin implementación',
  ),
);

final getLatestConversationUseCaseProvider = Provider(
  (ref) => GetLatestConversationUseCase(ref.watch(assistantRepositoryProvider)),
);

final listConversationsUseCaseProvider = Provider(
  (ref) => ListConversationsUseCase(ref.watch(assistantRepositoryProvider)),
);

final openConversationUseCaseProvider = Provider(
  (ref) => OpenConversationUseCase(ref.watch(assistantRepositoryProvider)),
);

/// Conversaciones guardadas con el coach, de la más reciente a la más antigua.
final conversationsProvider =
    FutureProvider.autoDispose<List<ConversationSummary>>(
      (ref) async =>
          (await ref.watch(listConversationsUseCaseProvider)()).getOrThrow(),
    );

final askCoachUseCaseProvider = Provider(
  (ref) => AskCoachUseCase(ref.watch(assistantRepositoryProvider)),
);

/// Estado del chat: la conversación abierta y si se está esperando una respuesta.
class ChatState {
  const ChatState({
    this.conversationId,
    this.messages = const [],
    this.sending = false,
    this.partial,
  });

  final int? conversationId;
  final List<ChatMessage> messages;
  final bool sending;

  /// Respuesta que el modelo del celular está escribiendo (texto acumulado).
  final String? partial;

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? sending,
    String? Function()? partial,
  }) => ChatState(
    conversationId: conversationId,
    messages: messages ?? this.messages,
    sending: sending ?? this.sending,
    partial: partial != null ? partial() : this.partial,
  );
}

/// Conversación con el coach. Con la IA del celular la conversación se guarda en el
/// dispositivo; en línea, la más reciente del servidor (enviar exige conexión).
class CoachChatController extends AsyncNotifier<ChatState> {
  bool get _onDevice => ref.read(coachModeProvider) == CoachMode.device;

  @override
  Future<ChatState> build() async {
    // Otra cuenta, otro chat: no se arrastran mensajes de la sesión anterior.
    ref.watch(authControllerProvider.select((s) => s.value?.user.id));
    if (ref.watch(coachModeProvider) == CoachMode.device) {
      final messages = (await ref.watch(
        loadLocalConversationUseCaseProvider,
      )()).getOrThrow();
      return ChatState(messages: messages);
    }
    final conversation = (await ref.watch(
      getLatestConversationUseCaseProvider,
    )()).getOrThrow();
    return ChatState(
      conversationId: conversation?.id,
      messages: conversation?.messages ?? const [],
    );
  }

  /// Envía [text]. Devuelve el [Failure] si no se pudo (el mensaje no se guardó y se
  /// quita del chat para que la persona lo reenvíe), o `null` si salió bien.
  Future<Failure?> send(String text) async {
    final current = state.value;
    if (current == null || current.sending) return null;
    final pending = ChatMessage(id: -1, isUser: true, text: text.trim());
    state = AsyncData(
      current.copyWith(messages: [...current.messages, pending], sending: true),
    );
    if (_onDevice) return _sendOnDevice(current, text);
    // Solo cuenta al abrir una conversación nueva: queda en el emprendimiento activo.
    final ventureId = current.conversationId == null
        ? await ref.read(currentVentureIdProvider.future)
        : null;
    final result = await ref.read(askCoachUseCaseProvider)(
      text,
      conversationId: current.conversationId,
      ventureId: ventureId,
    );
    switch (result) {
      case Ok(:final value):
        state = AsyncData(
          ChatState(
            conversationId: value.conversationId,
            messages: [...current.messages, value.question, value.answer],
          ),
        );
        return null;
      case Err(:final failure):
        state = AsyncData(current.copyWith(sending: false));
        return failure;
    }
  }

  Future<Failure?> _sendOnDevice(ChatState before, String text) async {
    final result = await ref.read(askLocalCoachUseCaseProvider)(
      text,
      history: before.messages,
      onPartial: (partial) {
        final now = state.value;
        if (now != null && now.sending) {
          state = AsyncData(now.copyWith(partial: () => partial));
        }
      },
    );
    switch (result) {
      case Ok(:final value):
        state = AsyncData(
          ChatState(
            messages: [...before.messages, value.question, value.answer],
          ),
        );
        return null;
      case Err(:final failure):
        state = AsyncData(before);
        return failure;
    }
  }

  /// Reabre la conversación [id]. `null` si salió bien o el [Failure] para mostrarlo.
  Future<Failure?> open(int id) async {
    final current = state.value;
    if (current != null && current.sending) return null;
    final result = await ref.read(openConversationUseCaseProvider)(id);
    switch (result) {
      case Ok(:final value):
        state = AsyncData(
          ChatState(conversationId: value.id, messages: value.messages),
        );
        return null;
      case Err(:final failure):
        return failure;
    }
  }

  /// Empieza una conversación nueva. En línea, la anterior sigue guardada en el
  /// servidor; en el celular solo se guarda una, así que se borra.
  Future<void> startNew() async {
    final current = state.value;
    if (current == null || current.sending) return;
    if (_onDevice) await ref.read(clearLocalConversationUseCaseProvider)();
    state = const AsyncData(ChatState());
  }
}

final coachChatControllerProvider =
    AsyncNotifierProvider<CoachChatController, ChatState>(
      CoachChatController.new,
    );
