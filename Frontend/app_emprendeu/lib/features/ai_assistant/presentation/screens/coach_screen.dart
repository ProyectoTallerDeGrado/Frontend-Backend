import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/error/failure.dart';
import '../../../mentoring/index.dart';
import '../../domain/usecases/assistant_usecases.dart';
import '../assistant_routes.dart';
import '../controllers/assistant_providers.dart';
import '../widgets/message_bubble.dart';

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
    ref.listen(coachChatControllerProvider, (_, _) => _toBottom());

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
                          'Responde con la información del CIE-U.',
                          style: text.bodyMedium?.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
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
            Expanded(
              child: chat.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          error is Failure
                              ? error.message
                              : 'No se pudo cargar el chat.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: () =>
                              ref.invalidate(coachChatControllerProvider),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (state) => state.messages.isEmpty
                    ? _EmptyChat(onPick: (q) => _send(q))
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
                          if (state.sending)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text(
                                'El coach está escribiendo…',
                                style: text.bodySmall?.copyWith(
                                  color: AppColors.muted,
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
            _Composer(
              controller: _input,
              sending: chat.value?.sending ?? false,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat({required this.onPick});

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
              Icons.smart_toy_outlined,
              size: 40,
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            Text('Hazme una pregunta', style: text.titleMedium),
            const SizedBox(height: 6),
            Text(
              'Te respondo con los documentos del CIE-U. Si no tengo información suficiente, te lo digo y te sugiero hablar con un mentor.',
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 12),
      child: Row(
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
              decoration: const InputDecoration(
                hintText: 'Escribe tu pregunta',
                counterText: '',
              ),
            ),
          ),
          IconButton.filled(
            tooltip: 'Enviar',
            onPressed: canSend ? () => widget.onSend() : null,
            icon: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}
