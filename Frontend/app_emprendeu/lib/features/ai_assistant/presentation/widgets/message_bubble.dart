import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/chat_message.dart';

/// Burbuja de un mensaje; la del coach muestra las fuentes que usó.
class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message, this.footer});

  final ChatMessage message;

  /// Acción bajo la respuesta (p. ej. «Agendar una mentoría»).
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final user = message.isUser;
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        child: Semantics(
          container: true,
          label: '${user ? 'Tú' : 'Coach'}: ${message.text}',
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: user ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: user ? null : Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.text,
                  style: text.bodyMedium?.copyWith(
                    color: user ? Colors.white : AppColors.ink,
                  ),
                ),
                if (!user && message.sources.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Fuentes: ${message.sources.join(', ')}',
                    style: text.bodySmall?.copyWith(color: AppColors.muted),
                  ),
                ],
                ?footer,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
