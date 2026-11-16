import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/utils/date_format.dart';
import '../../domain/entities/booking_status.dart';
import '../../domain/entities/mentoring_session.dart';
import '../controllers/booking_providers.dart';
import '../mentoring_routes.dart';
import '../widgets/session_card.dart';
import '../../../../shared/widgets/state_views.dart';

/// Pestaña «Mentorías»: mis sesiones por estado y periodo, y el acceso a agendar.
class MentoringScreen extends ConsumerStatefulWidget {
  const MentoringScreen({super.key});

  @override
  ConsumerState<MentoringScreen> createState() => _MentoringScreenState();
}

class _MentoringScreenState extends ConsumerState<MentoringScreen> {
  SessionFilter _filter = SessionFilter.upcoming;
  DateTimeRange? _range;

  static const _labels = {
    SessionFilter.upcoming: 'Próximas',
    SessionFilter.done: 'Realizadas',
    SessionFilter.cancelled: 'Canceladas',
  };

  SessionsQuery get _query =>
      (filter: _filter, from: _range?.start, to: _range?.end);

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
      initialDateRange: _range,
      helpText: 'Periodo de las mentorías',
      cancelText: 'Cancelar',
      confirmText: 'Aplicar',
      saveText: 'Aplicar',
    );
    if (picked != null && mounted) setState(() => _range = picked);
  }

  Future<void> _refresh() async {
    ref.invalidate(bookingStatusProvider);
    ref.invalidate(mySessionsProvider);
    await ref
        .read(mySessionsProvider(_query).future)
        .catchError((_) => <MentoringSession>[]);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final sessions = ref.watch(mySessionsProvider(_query));
    final status = ref.watch(bookingStatusProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            children: [
              Text('Mentorías', style: text.headlineMedium),
              const SizedBox(height: 4),
              Text(
                'Tus sesiones con el asesor que acompaña a tu emprendimiento.',
                style: text.bodyMedium?.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: 18),
              _BookingCta(status: status),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => context.push(MentoringRoutes.history),
                icon: const Icon(Icons.timeline, size: 20),
                label: const Text('Ver historial del emprendimiento'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => context.push(MentoringRoutes.tasks),
                icon: const Icon(Icons.checklist, size: 20),
                label: const Text('Tareas y compromisos'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final f in SessionFilter.values)
                    ChoiceChip(
                      label: Text(_labels[f]!),
                      selected: _filter == f,
                      onSelected: (_) => setState(() => _filter = f),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ActionChip(
                      avatar: const Icon(Icons.date_range, size: 18),
                      label: Text(
                        _range == null
                            ? 'Filtrar por periodo'
                            : '${shortDay(_range!.start)} – ${shortDay(_range!.end)}',
                      ),
                      onPressed: _pickRange,
                    ),
                    if (_range != null)
                      TextButton(
                        onPressed: () => setState(() => _range = null),
                        child: const Text('Quitar periodo'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              sessions.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => _ErrorState(
                  message: error is Failure
                      ? error.message
                      : 'No se pudieron cargar tus mentorías.',
                  onRetry: () => ref.invalidate(mySessionsProvider),
                ),
                data: (items) => items.isEmpty
                    ? _EmptyState(filter: _filter, hasRange: _range != null)
                    : Column(
                        children: [
                          for (final s in items) ...[
                            SessionCard(
                              session: s,
                              onTap: () =>
                                  context.push(MentoringRoutes.session(s.id)),
                            ),
                            const SizedBox(height: 12),
                          ],
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

/// Botón «Agendar mentoría», o el motivo por el que aún no se puede.
class _BookingCta extends StatelessWidget {
  const _BookingCta({required this.status});

  final AsyncValue<BookingStatus> status;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final value = status.value;
    final enabled = value?.enabled ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 52,
          child: FilledButton.icon(
            onPressed: enabled
                ? () => context.push(MentoringRoutes.book)
                : null,
            icon: const Icon(Icons.event_available, size: 20),
            label: const Text('Agendar mentoría'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        if (value != null && !value.enabled && (value.reason ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              value.reason!,
              style: text.bodySmall?.copyWith(
                fontSize: 13,
                color: AppColors.muted,
              ),
            ),
          ),
        if (status.hasError)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'No se pudo comprobar si puedes agendar. Desliza hacia abajo para reintentar.',
              style: text.bodySmall?.copyWith(
                fontSize: 13,
                color: AppColors.muted,
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter, required this.hasRange});

  final SessionFilter filter;
  final bool hasRange;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final message = hasRange
        ? 'No hay mentorías en ese periodo.'
        : switch (filter) {
            SessionFilter.upcoming =>
              'No tienes mentorías próximas. Agenda una cuando quieras.',
            SessionFilter.done => 'Todavía no tienes mentorías realizadas.',
            SessionFilter.cancelled => 'No tienes mentorías canceladas.',
          };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          const Icon(
            Icons.event_busy_outlined,
            size: 40,
            color: AppColors.muted,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ErrorState(
      message: message,
      onRetry: onRetry,
      padding: const EdgeInsets.symmetric(vertical: 32),
    );
  }
}
