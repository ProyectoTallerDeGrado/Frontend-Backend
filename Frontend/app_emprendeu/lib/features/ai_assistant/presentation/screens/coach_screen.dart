import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/error/failure.dart';
import '../../../../shared/widgets/motion.dart';
import '../../../auth/index.dart';
import '../../../mentoring/index.dart';
import '../../domain/usecases/assistant_usecases.dart';
import '../assistant_routes.dart';
import '../../domain/entities/chat_message.dart';
import '../controllers/assistant_providers.dart';
import '../controllers/local_ai_providers.dart';
import '../controllers/local_coach_providers.dart';
import '../widgets/message_bubble.dart';
import '../../../../shared/widgets/state_views.dart';

const _suggestions = [
  '¿Cómo calculo mis costos?',
  '¿Cómo valido mi idea con clientes?',
  '¿Qué es un modelo de negocio?',
];

/// Pestaña «Coach»: chat con el asistente, que responde con la base documental del CIE-U.
class CoachScreen extends ConsumerStatefulWidget {
  const CoachScreen({super.key});

  @override
  ConsumerState<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends ConsumerState<CoachScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  String? _error;

  @override
  void initState() {
    super.initState();
    // Con la IA del celular, trae los documentos nuevos del CIE-U (si hay red).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(coachModeProvider) == CoachMode.device) {
        ref.read(localKnowledgeControllerProvider.notifier).syncIfStale();
      }
    });
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send([String? text]) async {
    final message = (text ?? _input.text).trim();
    if (message.isEmpty) return;
    setState(() => _error = null);
    _input.clear();
    final failure = await ref
        .read(coachChatControllerProvider.notifier)
        .send(message);
    if (!mounted) return;
    if (failure != null) {
      // Nada se guardó: se devuelve el texto al campo para reenviarlo.
      _input.text = message;
      _input.selection = TextSelection.collapsed(offset: message.length);
      setState(() => _error = failure.message);
    }
    _toBottom();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final chat = ref.watch(coachChatControllerProvider);
    final mode = ref.watch(coachModeProvider);
    final onDevice = mode == CoachMode.device;
    ref.listen(coachChatControllerProvider, (_, _) => _toBottom());
    ref.listen(coachModeProvider, (_, next) {
      setState(() => _error = null);
      if (next == CoachMode.device) {
        ref.read(localKnowledgeControllerProvider.notifier).syncIfStale();
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text('Coach IA', style: text.headlineMedium),
                        ),
                        Text(
                          onDevice
                              ? 'Responde en tu celular, sin internet.'
                              : 'Responde con la información del CIE-U.',
                          style: text.bodyMedium?.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Las conversaciones anteriores viven en el servidor.
                  if (!onDevice)
                    IconButton(
                      tooltip: 'Conversaciones anteriores',
                      onPressed: () =>
                          context.push(AssistantRoutes.conversations),
                      icon: const Icon(Icons.history),
                    ),
                  IconButton(
                    tooltip: 'Nueva conversación',
                    onPressed: () {
                      setState(() => _error = null);
                      ref.read(coachChatControllerProvider.notifier).startNew();
                    },
                    icon: const Icon(Icons.add_comment_outlined),
                  ),
                ],
              ),
            ),
            if (ref.watch(localAiReadyProvider)) _ModeBar(mode: mode),
            Expanded(
              child: chat.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: ErrorState(
                      message: error is Failure
                          ? error.message
                          : 'No se pudo cargar el chat.',
                      onRetry: () =>
                          ref.invalidate(coachChatControllerProvider),
                    ),
                  ),
                ),
                data: (state) => state.messages.isEmpty
                    ? _EmptyChat(onDevice: onDevice, onPick: (q) => _send(q))
                    : ListView(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        children: [
                          for (final m in state.messages)
                            MessageBubble(
                              message: m,
                              footer: m.suggestMentor && !m.isUser
                                  ? _MentorHint(
                                      onTap: () =>
                                          context.go(MentoringRoutes.sessions),
                                    )
                                  : null,
                            ),
                          if (state.sending && (state.partial ?? '').isNotEmpty)
                            MessageBubble(
                              message: ChatMessage(
                                id: -2,
                                isUser: false,
                                text: state.partial!,
                              ),
                            )
                          else if (state.sending)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 10),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: TypingDots(
                                  semanticsLabel: 'El coach está escribiendo',
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ),
            if (_error != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accentTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _error!,
                  style: text.bodyMedium?.copyWith(color: AppColors.accentOn),
                ),
              ),
            TourTarget(
              id: 'coach-input',
              child: _Composer(
                controller: _input,
                sending: chat.value?.sending ?? false,
                onSend: _send,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat({required this.onDevice, required this.onPick});

  final bool onDevice;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_awesome_outlined,
              size: 40,
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            Text('Hazme una pregunta', style: text.titleMedium),
            const SizedBox(height: 6),
            Text(
              onDevice
                  ? 'Te respondo en tu celular con los documentos del CIE-U, sin internet. Si no tengo información suficiente, te lo digo y te sugiero hablar con un mentor.'
                  : 'Te respondo con los documentos del CIE-U. Si no tengo información suficiente, te lo digo y te sugiero hablar con un mentor.',
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final s in _suggestions)
                  ActionChip(label: Text(s), onPressed: () => onPick(s)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MentorHint extends StatelessWidget {
  const _MentorHint({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: TextButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.event_available, size: 18),
        label: const Text('Agendar una mentoría'),
      ),
    );
  }
}

class _Composer extends StatefulWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final Future<void> Function([String? text]) onSend;

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final canSend = !widget.sending && widget.controller.text.trim().isNotEmpty;
    // Burbuja de chat (design.md §3.6): más redonda que un campo de formulario.
    OutlineInputBorder bubble(Color color, [double width = 1.5]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: color, width: width),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 12, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  enabled: !widget.sending,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: maxCoachMessageLength,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Escribe tu pregunta',
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 13,
                    ),
                    border: bubble(AppColors.borderStrong),
                    enabledBorder: bubble(AppColors.borderStrong),
                    disabledBorder: bubble(AppColors.border),
                    focusedBorder: bubble(AppColors.primary, 2),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: 'Enviar',
                onPressed: canSend ? () => widget.onSend() : null,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                icon: const Icon(Icons.send),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'La IA no sustituye a un asesor o mentor especializado.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(fontSize: 12, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

/// Elegir dónde responde el coach y, en el celular, el estado de sus documentos.
class _ModeBar extends ConsumerWidget {
  const _ModeBar({required this.mode});

  final CoachMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final knowledge = ref.watch(localKnowledgeControllerProvider).value;
    final String? status = switch (knowledge) {
      _ when mode != CoachMode.device => null,
      null => null,
      LocalKnowledgeState(syncing: true, :final done, :final total) =>
        total == 0
            ? 'Buscando documentos nuevos…'
            : 'Preparando documentos $done de $total…',
      LocalKnowledgeState(:final error?) when knowledge.status.documents == 0 =>
        error,
      LocalKnowledgeState(:final status) when status.documents == 0 =>
        'Aún no hay guías del CIE-U en tu celular: se descargan con internet '
            'cuando el CIE-U las carga.',
      LocalKnowledgeState(:final status) =>
        '${status.documents} documentos del CIE-U en tu celular',
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('En tu celular'),
                avatar: const Icon(Icons.smartphone, size: 16),
                selected: mode == CoachMode.device,
                onSelected: (_) => ref
                    .read(coachModePreferenceProvider.notifier)
                    .choose(CoachMode.device),
              ),
              ChoiceChip(
                label: const Text('En línea'),
                avatar: const Icon(Icons.cloud_outlined, size: 16),
                selected: mode == CoachMode.online,
                onSelected: (_) => ref
                    .read(coachModePreferenceProvider.notifier)
                    .choose(CoachMode.online),
              ),
            ],
          ),
          if (status != null)
            Row(
              children: [
                Expanded(
                  child: Text(
                    status,
                    style: text.bodySmall?.copyWith(color: AppColors.muted),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => context.push(AssistantRoutes.ownFiles),
                  icon: const Icon(Icons.folder_special_outlined, size: 16),
                  label: const Text('Tus archivos'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
