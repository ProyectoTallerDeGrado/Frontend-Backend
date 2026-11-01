import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/connectivity/online_controller.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/utils/date_format.dart';
import '../../domain/entities/progress_log.dart';
import '../controllers/mentoring_providers.dart';

/// «Mis avances»: botón para registrar y lista de lo ya registrado.
class ProgressSection extends ConsumerWidget {
  const ProgressSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final logs = ref.watch(progressLogsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text('Mis avances', style: text.titleMedium),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 44,
              child: FilledButton.icon(
                onPressed: () => _openSheet(context),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Registrar avance'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.navy900,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: text.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        logs.when(
          data: (list) => list.isEmpty
              ? Text(
                  'Todavía no registras avances. Cuenta qué lograste esta semana.',
                  style: text.bodyMedium?.copyWith(
                    fontSize: 14,
                    color: AppColors.muted,
                  ),
                )
              : Column(children: [for (final l in list.take(10)) _LogCard(l)]),
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Row(
            children: [
              Expanded(
                child: Text(
                  e is Failure
                      ? e.message
                      : 'No se pudieron cargar los avances.',
                ),
              ),
              TextButton(
                onPressed: () => ref.invalidate(progressLogsProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openSheet(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.surface,
    barrierColor: AppColors.navy950.withValues(alpha: 0.55),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (_) => const _LogSheet(),
  );
}

class _LogCard extends StatelessWidget {
  const _LogCard(this.log);

  final ProgressLog log;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final (bg, fg, label) = log.pendingSync
        ? (
            AppColors.warningTint,
            AppColors.warningOn,
            'Pendiente de sincronizar',
          )
        : (AppColors.successTint, AppColors.successDark, 'Sincronizado');
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            log.text,
            style: text.bodyMedium?.copyWith(fontSize: 15, height: 1.4),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                relativeTime(log.createdAt),
                style: text.bodySmall?.copyWith(
                  fontSize: 13,
                  color: AppColors.muted,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  label,
                  style: text.bodySmall?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LogSheet extends ConsumerStatefulWidget {
  const _LogSheet();

  @override
  ConsumerState<_LogSheet> createState() => _LogSheetState();
}

class _LogSheetState extends ConsumerState<_LogSheet> {
  final _controller = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final failure = await ref
        .read(progressLogsProvider.notifier)
        .add(_controller.text);
    if (!mounted) return;
    if (failure == null) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _saving = false;
        _error = failure.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final online = ref.watch(onlineProvider);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        28 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.borderStrong,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Semantics(
              header: true,
              child: Text(
                'Registrar avance',
                style: text.titleLarge?.copyWith(fontSize: 20),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              '¿Qué avanzaste?',
              style: text.bodyMedium?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              autofocus: true,
              minLines: 4,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Describe tu avance o hito alcanzado',
                errorText: _error,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              online ? 'Se guardará en el historial de tu emprendimiento.' : 'Sin conexión: se guardará en tu dispositivo y se enviará al volver la red.',
              style: text.bodySmall?.copyWith(
                fontSize: 13,
                height: 1.4,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.ink,
                        side: const BorderSide(
                          color: AppColors.borderStrong,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 14,
                  child: SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Guardar'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
