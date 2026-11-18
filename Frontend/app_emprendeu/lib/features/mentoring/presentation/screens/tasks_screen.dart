import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/utils/date_format.dart';
import '../../domain/entities/task.dart';
import '../controllers/booking_providers.dart';
import '../../../../shared/widgets/state_views.dart';

/// Tareas y compromisos pendientes: lo que debes hacer, con tipo, estado y fechas (CU22).
class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  TaskFilter _filter = const TaskFilter();

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
      initialDateRange: _filter.from == null || _filter.to == null
          ? null
          : DateTimeRange(start: _filter.from!, end: _filter.to!),
      helpText: 'Fecha prevista',
      cancelText: 'Cancelar',
      confirmText: 'Aplicar',
      saveText: 'Aplicar',
    );
    if (picked != null && mounted) {
      setState(
        () => _filter = TaskFilter(
          kind: _filter.kind,
          state: _filter.state,
          from: picked.start,
          to: picked.end,
        ),
      );
    }
  }

  void _set({TaskKind? kind, bool anyKind = false, TaskState? state}) =>
      setState(
        () => _filter = TaskFilter(
          kind: anyKind ? null : (kind ?? _filter.kind),
          state: state ?? _filter.state,
          from: _filter.from,
          to: _filter.to,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final tasks = ref.watch(tasksProvider(_filter));
    final hasRange = _filter.from != null && _filter.to != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Tareas y compromisos')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(tasksProvider);
            await ref
                .read(tasksProvider(_filter).future)
                .catchError((_) => <Task>[]);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Text(
                'Lo que te toca hacer en tu emprendimiento.',
                style: text.bodyMedium?.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Pendientes'),
                    selected: _filter.state == TaskState.pending,
                    onSelected: (_) => _set(state: TaskState.pending),
                  ),
                  ChoiceChip(
                    label: const Text('Cumplidas'),
                    selected: _filter.state == TaskState.done,
                    onSelected: (_) => _set(state: TaskState.done),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Todas'),
                    selected: _filter.kind == null,
                    onSelected: (_) => _set(anyKind: true),
                  ),
                  ChoiceChip(
                    label: const Text('Compromisos'),
                    selected: _filter.kind == TaskKind.commitment,
                    onSelected: (_) => _set(kind: TaskKind.commitment),
                  ),
                  ChoiceChip(
                    label: const Text('Hitos'),
                    selected: _filter.kind == TaskKind.milestone,
                    onSelected: (_) => _set(kind: TaskKind.milestone),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.date_range, size: 18),
                    label: Text(
                      hasRange
                          ? '${shortDay(_filter.from!)} – ${shortDay(_filter.to!)}'
                          : 'Filtrar por fecha',
                    ),
                    onPressed: _pickRange,
                  ),
                  if (hasRange)
                    TextButton(
                      onPressed: () => setState(
                        () => _filter = TaskFilter(
                          kind: _filter.kind,
                          state: _filter.state,
                        ),
                      ),
                      child: const Text('Quitar fecha'),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              tasks.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => ErrorState(
                  message: error is Failure
                      ? error.message
                      : 'No se pudieron cargar tus tareas.',
                  onRetry: () => ref.invalidate(tasksProvider),
                ),
                data: (items) => items.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Text(
                          _filter.state == TaskState.pending
                              ? 'No tienes tareas pendientes. ¡Buen trabajo!'
                              : 'Todavía no hay tareas cumplidas con ese filtro.',
                          textAlign: TextAlign.center,
                          style: text.bodyMedium?.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                      )
                    : Column(
                        children: [for (final t in items) _TaskTile(task: t)],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final isMilestone = task.kind == TaskKind.milestone;
    final done = task.state == TaskState.done;
    final badge = done
        ? ('Cumplido', AppColors.successTint, AppColors.successDark)
        : task.overdue
        ? ('Vencido', AppColors.accentTint, AppColors.accentOn)
        : ('Pendiente', AppColors.blue50, AppColors.primary);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        container: true,
        label:
            '${isMilestone ? 'Hito' : 'Compromiso'}. ${task.title}. ${badge.$1}',
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.blue100),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.blue50,
                child: Icon(
                  isMilestone ? Icons.flag_outlined : Icons.handshake_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMilestone ? 'Hito' : 'Compromiso',
                      style: text.labelMedium?.copyWith(color: AppColors.muted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      task.title,
                      style: text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if ((task.detail ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(task.detail!, style: text.bodyMedium),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      [
                        if (!done) dueLabel(task.dueAt),
                        if ((task.responsible ?? '').isNotEmpty)
                          'Responsable: ${task.responsible}',
                      ].join(' · '),
                      style: text.bodySmall?.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
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
        ),
      ),
    );
  }
}
