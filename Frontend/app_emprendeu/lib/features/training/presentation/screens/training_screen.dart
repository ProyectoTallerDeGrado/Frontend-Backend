import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/utils/date_format.dart';
import '../../domain/entities/training.dart';
import '../controllers/training_providers.dart';

/// Capacitaciones del programa: inscribirse y ver la asistencia propia (CU29).
class TrainingScreen extends ConsumerWidget {
  const TrainingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final trainings = ref.watch(trainingsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Capacitaciones')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(trainingsProvider);
            await ref
                .read(trainingsProvider.future)
                .catchError((_) => <Training>[]);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Text(
                'Talleres y charlas del CIE-U. Inscríbete en los que te interesen.',
                style: text.bodyMedium?.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: 16),
              trainings.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Column(
                  children: [
                    Text(
                      error is Failure
                          ? error.message
                          : 'No se pudieron cargar las capacitaciones.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => ref.invalidate(trainingsProvider),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
                data: (items) => items.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Text(
                          'Todavía no hay capacitaciones publicadas.',
                          textAlign: TextAlign.center,
                          style: text.bodyMedium?.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          for (final t in items) _TrainingTile(training: t),
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

class _TrainingTile extends ConsumerWidget {
  const _TrainingTile({required this.training});

  final Training training;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final t = training;
    final badge = switch ((t.enrolled, t.attended)) {
      (true, true) => (
        'Asististe',
        AppColors.successTint,
        AppColors.successDark,
      ),
      (true, false) => (
        'No asististe',
        AppColors.warningTint,
        AppColors.warningOn,
      ),
      (true, null) => ('Inscrito', AppColors.blue100, AppColors.primary),
      _ => null,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                  t.title,
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (badge != null)
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
          if ((t.description ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(t.description!, style: text.bodyMedium),
          ],
          const SizedBox(height: 6),
          Text(
            [
              if (t.date != null) sessionWhen(t.date!.toLocal()),
              if (t.modality != null) t.modality!,
              if (t.status != 'programada') t.status,
            ].join(' · '),
            style: text.bodySmall?.copyWith(color: AppColors.muted),
          ),
          if (t.canEnroll) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 44,
              child: FilledButton(
                onPressed: () async {
                  final failure = await ref
                      .read(trainingControllerProvider.notifier)
                      .enroll(t.id);
                  if (failure != null && context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(failure.message)));
                  }
                },
                child: const Text('Inscribirme'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
