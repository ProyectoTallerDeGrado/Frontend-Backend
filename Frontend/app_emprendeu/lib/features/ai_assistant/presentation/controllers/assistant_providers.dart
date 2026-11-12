import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/assistant_repository.dart';
import '../../domain/usecases/assistant_usecases.dart';
import '../../../ventures/index.dart';

/// Contrato del repositorio; la implementación se inyecta en `app/providers.dart`.
final assistantRepositoryProvider = Provider<AssistantRepository>(
  (ref) => throw UnimplementedError(
    'assistantRepositoryProvider sin implementación',
  ),
);

final getLatestConversationUseCaseProvider = Provider(
  (ref) => GetLatestConversationUseCase(ref.watch(assistantRepositoryProvider)),
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
  });

  final int? conversationId;
  final List<ChatMessage> messages;
  final bool sending;

  ChatState copyWith({List<ChatMessage>? messages, bool? sending}) => ChatState(
    conversationId: conversationId,
    messages: messages ?? this.messages,
    sending: sending ?? this.sending,
  );
}

/// Conversación con el coach. Al abrir carga la más reciente; enviar exige conexión.
class CoachChatController extends AsyncNotifier<ChatState> {
  @override
  Future<ChatState> build() async {
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

  /// Empieza una conversación nueva (la anterior sigue guardada en el servidor).
  void startNew() {
    final current = state.value;
    if (current == null || current.sending) return;
    state = const AsyncData(ChatState());
  }
}

final coachChatControllerProvider =
    AsyncNotifierProvider<CoachChatController, ChatState>(
      CoachChatController.new,
    );
