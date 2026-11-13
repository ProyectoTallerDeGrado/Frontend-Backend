import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/utils/date_format.dart';
import '../../domain/entities/mentoring_session.dart';
import '../controllers/booking_providers.dart';
import '../widgets/session_card.dart';

/// Detalle de una mentoría; si está programada se puede cancelar (CU23).
class SessionDetailScreen extends ConsumerStatefulWidget {
  const SessionDetailScreen({super.key, required this.sessionId});

  final int sessionId;

  @override
  ConsumerState<SessionDetailScreen> createState() =>
      _SessionDetailScreenState();
}

class _SessionDetailScreenState extends ConsumerState<SessionDetailScreen> {
  bool _cancelling = false;

  Future<void> _confirmCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cancelar la mentoría?'),
        content: const Text(
          'El horario quedará libre para otras personas. '
          'Podrás agendar otra cuando quieras.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cancelar mentoría'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _cancelling = true);
    final failure = await ref
        .read(bookingControllerProvider.notifier)
        .cancel(widget.sessionId);
    if (!mounted) return;
    setState(() => _cancelling = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(failure?.message ?? 'Mentoría cancelada.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final detail = ref.watch(sessionDetailProvider(widget.sessionId));
    return Scaffold(
      appBar: AppBar(title: const Text('Mentoría')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(sessionDetailProvider(widget.sessionId));
            await ref
                .read(sessionDetailProvider(widget.sessionId).future)
                .catchError(
                  (_) => const MentoringSession(
                    id: 0,
                    state: SessionState.scheduled,
                  ),
                );
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              detail.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Column(
                  children: [
                    Text(
                      error is Failure
                          ? error.message
                          : 'No se pudo cargar la mentoría.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => ref.invalidate(
                        sessionDetailProvider(widget.sessionId),
                      ),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
                data: (s) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SessionCard(session: s),
                    const SizedBox(height: 16),
                    _Row(label: 'Emprendimiento', value: s.ventureName),
                    _Row(label: 'Asesor', value: s.mentorName),
                    _Row(label: 'Modalidad', value: s.modality),
                    if (s.state == SessionState.done && s.doneAt != null)
                      _Row(label: 'Realizada', value: sessionWhen(s.doneAt!)),
                    _Row(label: 'Observaciones', value: s.notes),
                    if (s.state == SessionState.scheduled) ...[
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: _cancelling ? null : _confirmCancel,
                          icon: _cancelling
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.event_busy_outlined, size: 20),
                          label: const Text('Cancelar mentoría'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.accentOn,
                            side: const BorderSide(color: AppColors.accentOn),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Solo puedes cancelar mentorías que aún no se realizaron.',
                        textAlign: TextAlign.center,
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

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    if ((value ?? '').isEmpty) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: text.bodySmall?.copyWith(color: AppColors.muted),
            ),
          ),
          Expanded(child: Text(value!, style: text.bodyMedium)),
        ],
      ),
    );
  }
}
