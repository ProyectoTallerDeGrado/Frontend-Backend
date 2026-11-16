import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/utils/date_format.dart';
import '../../domain/entities/commitment.dart';
import '../controllers/mentoring_providers.dart';

/// «Compromisos pendientes»: lista con casillas que funcionan también sin conexión.
class CommitmentsSection extends ConsumerWidget {
  const CommitmentsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final commitments = ref.watch(commitmentsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text('Compromisos pendientes', style: text.titleMedium),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${commitments.value?.where((c) => !c.done).length ?? 0} por hacer',
              style: text.bodyMedium?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(20),
          ),
          child: commitments.when(
            data: (list) {
              final pending = [
                for (final c in list)
                  if (!c.done) c,
              ];
              final done = [
                for (final c in list)
                  if (c.done) c,
              ];
              if (list.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Text(
                    'Aún no tienes compromisos. Tu mentor los asignará en cada sesión.',
                    style: text.bodyMedium?.copyWith(
                      fontSize: 14,
                      color: AppColors.muted,
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  if (pending.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: Text(
                        'No tienes compromisos pendientes. ¡Buen trabajo!',
                        style: text.bodyMedium?.copyWith(
                          fontSize: 14,
                          color: AppColors.muted,
                        ),
                      ),
                    )
                  else
                    for (final c in pending) _CommitmentTile(c),
                  // Los cumplidos quedan aparte para no mezclarlos con lo pendiente.
                  if (done.isNotEmpty)
                    Material(
                      color: Colors.transparent,
                      child: Theme(
                        data: Theme.of(context)
                            .copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          title: Text(
                            'Cumplidos (${done.length})',
                            style: text.bodyMedium?.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.muted,
                            ),
                          ),
                          children: [for (final c in done) _CommitmentTile(c)],
                        ),
                      ),
                    ),
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      e is Failure
                          ? e.message
                          : 'No se pudieron cargar los compromisos.',
                    ),
                  ),
                  TextButton(
                    onPressed: () => ref.invalidate(commitmentsProvider),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CommitmentTile extends ConsumerWidget {
  const _CommitmentTile(this.commitment);

  final Commitment commitment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final c = commitment;
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Semantics(
            checked: c.done,
            label:
                '${c.done ? 'Marcar como pendiente' : 'Marcar como cumplido'}: ${c.description}',
            child: InkResponse(
              onTap: () async {
                HapticFeedback.selectionClick();
                final failure = await ref
                    .read(commitmentsProvider.notifier)
                    .toggle(c);
                if (failure != null && context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(failure.message)));
                }
              },
              radius: 28,
              child: SizedBox(
                width: 48,
                height: 56,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: c.done ? AppColors.success : Colors.white,
                      border: Border.all(
                        color: c.done
                            ? AppColors.success
                            : AppColors.outlineOff,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 200),
                      scale: c.done ? 1 : 0.4,
                      child: Icon(
                        Icons.check,
                        size: 16,
                        color: c.done ? Colors.white : Colors.transparent,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.description,
                    style: text.bodyMedium?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                      color: c.done ? AppColors.muted : AppColors.ink,
                      decoration: c.done ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Wrap(
                    spacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        dueLabel(c.dueDate),
                        style: text.bodySmall?.copyWith(
                          fontSize: 13,
                          color: AppColors.muted,
                        ),
                      ),
                      if (c.pendingSync)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warningTint,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Pendiente de sincronizar',
                            style: text.bodySmall?.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.warningOn,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
