import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/utils/date_format.dart';
import '../../domain/entities/history_event.dart';
import '../../domain/entities/history_filter.dart';
import '../controllers/booking_providers.dart';

const _kinds = <HistoryKind, (String, IconData)>{
  HistoryKind.session: ('Sesión', Icons.event_available),
  HistoryKind.progress: ('Avance', Icons.trending_up),
  HistoryKind.milestone: ('Hito', Icons.flag_outlined),
  HistoryKind.recommendation: ('Recomendación', Icons.lightbulb_outline),
  HistoryKind.commitment: ('Compromiso', Icons.handshake_outlined),
  HistoryKind.stage: ('Etapa', Icons.rocket_launch_outlined),
};

/// Línea de tiempo del emprendimiento: sesiones, avances, hitos, recomendaciones,
/// compromisos y cambios de etapa (CU19).
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  HistoryFilter _filter = const HistoryFilter();

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 2),
      initialDateRange: _filter.from == null || _filter.to == null
          ? null
          : DateTimeRange(start: _filter.from!, end: _filter.to!),
      helpText: 'Periodo del historial',
      cancelText: 'Cancelar',
      confirmText: 'Aplicar',
      saveText: 'Aplicar',
    );
    if (picked != null && mounted) {
      setState(
        () => _filter = _filter.copyWith(from: picked.start, to: picked.end),
      );
    }
  }

  void _toggleKind(HistoryKind kind, bool selected) {
    final kinds = {..._filter.kinds};
    selected ? kinds.add(kind) : kinds.remove(kind);
    setState(() => _filter = _filter.copyWith(kinds: kinds));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final history = ref.watch(historyProvider(_filter));
    return Scaffold(
      appBar: AppBar(title: const Text('Historial')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(historyProvider);
            await ref
                .read(historyProvider(_filter).future)
                .catchError((_) => <HistoryEvent>[]);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Text(
                'Todo lo que ha pasado en tu emprendimiento.',
                style: text.bodyMedium?.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Más reciente primero'),
                    selected: _filter.newestFirst,
                    onSelected: (_) => setState(
                      () => _filter = _filter.copyWith(newestFirst: true),
                    ),
                  ),
                  ChoiceChip(
                    label: const Text('Cronológico'),
                    selected: !_filter.newestFirst,
                    onSelected: (_) => setState(
                      () => _filter = _filter.copyWith(newestFirst: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entry in _kinds.entries)
                    FilterChip(
                      label: Text(entry.value.$1),
                      selected: _filter.kinds.contains(entry.key),
                      onSelected: (on) => _toggleKind(entry.key, on),
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
                      _filter.from == null || _filter.to == null
                          ? 'Filtrar por periodo'
                          : '${shortDay(_filter.from!)} – ${shortDay(_filter.to!)}',
                    ),
                    onPressed: _pickRange,
                  ),
                  if (_filter.isFiltered)
                    TextButton(
                      onPressed: () => setState(
                        () => _filter = HistoryFilter(
                          newestFirst: _filter.newestFirst,
                        ),
                      ),
                      child: const Text('Quitar filtros'),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              history.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Column(
                  children: [
                    Text(
                      error is Failure
                          ? error.message
                          : 'No se pudo cargar el historial.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => ref.invalidate(historyProvider),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
                data: (items) => items.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Text(
                          _filter.isFiltered
                              ? 'No hay eventos con esos filtros.'
                              : 'Todavía no hay actividad registrada en tu emprendimiento.',
                          textAlign: TextAlign.center,
                          style: text.bodyMedium?.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          for (final e in items) _HistoryTile(event: e),
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

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.event});

  final HistoryEvent event;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final (label, icon) = _kinds[event.kind]!;
    final date = event.date;
    final meta = [
      if (event.state != null) event.state!,
      if (event.author != null) 'por ${event.author}',
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        container: true,
        label: '$label. ${event.title}',
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
                child: Icon(icon, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      date == null ? label : '$label · ${sessionWhen(date)}',
                      style: text.labelMedium?.copyWith(color: AppColors.muted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      event.title,
                      style: text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if ((event.detail ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(event.detail!, style: text.bodyMedium),
                    ],
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        meta,
                        style: text.bodySmall?.copyWith(color: AppColors.muted),
                      ),
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
