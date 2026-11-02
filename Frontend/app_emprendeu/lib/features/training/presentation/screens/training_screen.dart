import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/utils/date_format.dart';
import '../../domain/entities/training.dart';
import '../controllers/training_providers.dart';

/// Capacitaciones publicadas del CIE-U y la asistencia propia (CU29).
class TrainingScreen extends ConsumerWidget {
  const TrainingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final trainings = ref.watch(publishedTrainingsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Capacitaciones')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(publishedTrainingsProvider);
            await ref
                .read(publishedTrainingsProvider.future)
                .catchError((_) => <Training>[]);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Text(
                'Talleres y charlas del programa. Aquí ves cuáles son y si asististe.',
                style: text.bodyMedium?.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: 14),
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
                    ),
                    OutlinedButton(
                      onPressed: () =>
                          ref.invalidate(publishedTrainingsProvider),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
                data: (items) => items.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'Todavía no hay capacitaciones publicadas.',
                          textAlign: TextAlign.center,
                          style: text.bodyMedium?.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                      )
                    : Column(children: [for (final t in items) _Card(t)]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Card extends ConsumerWidget {
  const _Card(this.training);

  final Training training;

  /// Estado propio frente a la capacitación: texto, color y si ya terminó.
  (String, Color)? _status() {
    final t = training;
    if (t.enrolled && t.attended == true) {
      return ('Asististe', AppColors.successDark);
    }
    if (t.enrolled && t.attended == false) {
      return ('No asististe', AppColors.error);
    }
    if (t.enrolled) {
      return (
        t.isDone ? 'Asistencia sin registrar' : 'Inscrito',
        AppColors.primary,
      );
    }
    if (t.isDone) return ('No participaste', AppColors.muted);
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final t = training;
    final status = _status();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
            Text(
              t.isDone ? 'Realizada' : 'Próxima',
              style: text.labelMedium?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 2),
            Text(
              t.title,
              style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            if ((t.description ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(t.description!, style: text.bodyMedium),
            ],
            const SizedBox(height: 6),
            Text(
              [
                if (t.date != null) sessionWhen(t.date!) else 'Sin fecha',
                if ((t.modality ?? '').isNotEmpty) t.modality!,
                if ((t.type ?? '').isNotEmpty) t.type!,
              ].join(' · '),
              style: text.bodySmall?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 8),
            if (status != null)
              Semantics(
                label: 'Tu estado: ${status.$1}',
                child: Text(
                  status.$1,
                  style: text.labelLarge?.copyWith(color: status.$2),
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: () async {
                  final failure = await ref
                      .read(trainingControllerProvider.notifier)
                      .enroll(t.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          failure == null
                              ? 'Te inscribiste en ${t.title}.'
                              : failure.message,
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.how_to_reg, size: 18),
                label: const Text('Inscribirme'),
              ),
          ],
        ),
      ),
    );
  }
}
