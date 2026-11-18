import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/utils/date_format.dart';
import '../../domain/entities/conversation_summary.dart';
import '../controllers/assistant_providers.dart';
import '../../../../shared/widgets/state_views.dart';

/// Conversaciones anteriores con el coach: elegir una la reabre en el chat (CU11).
class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    ConversationSummary c,
  ) async {
    final failure = await ref
        .read(coachChatControllerProvider.notifier)
        .open(c.id);
    if (!context.mounted) return;
    if (failure != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.message)));
      return;
    }
    context.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final conversations = ref.watch(conversationsProvider);
    final openId = ref.watch(coachChatControllerProvider).value?.conversationId;
    return Scaffold(
      appBar: AppBar(title: const Text('Conversaciones')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(conversationsProvider);
            await ref
                .read(conversationsProvider.future)
                .catchError((_) => <ConversationSummary>[]);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Text(
                'Tus conversaciones anteriores con el coach.',
                style: text.bodyMedium?.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              conversations.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => ErrorState(
                  message: error is Failure
                      ? error.message
                      : 'No se pudieron cargar las conversaciones.',
                  onRetry: () => ref.invalidate(conversationsProvider),
                ),
                data: (items) => items.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Text(
                          'Todavía no has hablado con el coach.',
                          textAlign: TextAlign.center,
                          style: text.bodyMedium?.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          for (final c in items)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Material(
                                color: AppColors.surface,
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(
                                    color: c.id == openId
                                        ? AppColors.primary
                                        : AppColors.border,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: ListTile(
                                  onTap: () => _open(context, ref, c),
                                  leading: const Icon(
                                    Icons.chat_bubble_outline,
                                    color: AppColors.primary,
                                  ),
                                  title: Text(
                                    c.when == null
                                        ? 'Conversación'
                                        : sessionWhen(c.when!),
                                  ),
                                  subtitle: Text(
                                    '${c.messageCount} '
                                    '${c.messageCount == 1 ? 'mensaje' : 'mensajes'}'
                                    '${c.id == openId ? ' · abierta' : ''}',
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
