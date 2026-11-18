import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/utils/date_format.dart';
import '../../domain/entities/venture_need.dart';
import '../controllers/needs_providers.dart';
import '../needs_routes.dart';
import '../../../../shared/widgets/state_views.dart';

/// Lo que el emprendedor reportó al CIE-U: necesidades y dificultades (CU24).
class NeedsScreen extends ConsumerWidget {
  const NeedsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final needs = ref.watch(myNeedsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Necesidades y dificultades')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(myNeedsProvider);
            await ref
                .read(myNeedsProvider.future)
                .catchError((_) => <VentureNeed>[]);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Text(
                'Cuéntale al CIE-U qué te falta o qué te está frenando, '
                'para que pueda acompañarte mejor.',
                style: text.bodyMedium?.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: () => context.push(NeedsRoutes.report),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Reportar'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              needs.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => ErrorState(
                  message: error is Failure
                      ? error.message
                      : 'No se pudieron cargar tus reportes.',
                  onRetry: () => ref.invalidate(myNeedsProvider),
                ),
                data: (items) => items.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Text(
                          'Todavía no has reportado nada.',
                          textAlign: TextAlign.center,
                          style: text.bodyMedium?.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                      )
                    : Column(
                        children: [for (final n in items) _NeedTile(need: n)],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NeedTile extends StatelessWidget {
  const _NeedTile({required this.need});

  final VentureNeed need;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final difficulty = need.kind == NeedKind.difficulty;
    final badge = need.resolved
        ? ('Resuelta', AppColors.successTint, AppColors.successDark)
        : ('Abierta', AppColors.warningTint, AppColors.warningOn);
    final priority = switch (need.priority) {
      NeedPriority.high => 'Prioridad alta',
      NeedPriority.low => 'Prioridad baja',
      NeedPriority.medium => 'Prioridad media',
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        container: true,
        label:
            '${difficulty ? 'Dificultad' : 'Necesidad'}. ${need.categoryName}. ${badge.$1}',
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.blue100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      difficulty ? 'Dificultad' : 'Necesidad',
                      style: text.labelMedium?.copyWith(color: AppColors.muted),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: badge.$2,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badge.$1,
                      style: text.bodySmall?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: badge.$3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                need.categoryName,
                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              if ((need.description ?? '').isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(need.description!, style: text.bodyMedium),
              ],
              const SizedBox(height: 6),
              Text(
                [
                  priority,
                  if (need.detectedAt != null)
                    'Reportada ${relativeTime(need.detectedAt!).toLowerCase()}',
                ].join(' · '),
                style: text.bodySmall?.copyWith(color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
