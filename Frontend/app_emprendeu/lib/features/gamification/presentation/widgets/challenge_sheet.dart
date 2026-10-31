import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/error/result.dart';
import '../../domain/entities/completion_result.dart';
import '../../domain/entities/journey.dart';
import '../controllers/gamification_providers.dart';

/// Hoja inferior con el detalle de un reto. Devuelve el [CompletionResult] si se cumplió.
Future<CompletionResult?> showChallengeSheet(
  BuildContext context,
  JourneyChallenge challenge,
) {
  return showModalBottomSheet<CompletionResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.surface,
    barrierColor: AppColors.navy950.withValues(alpha: 0.55),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (_) => _ChallengeSheet(challenge: challenge),
  );
}

class _ChallengeSheet extends ConsumerStatefulWidget {
  const _ChallengeSheet({required this.challenge});

  final JourneyChallenge challenge;

  @override
  ConsumerState<_ChallengeSheet> createState() => _ChallengeSheetState();
}

class _ChallengeSheetState extends ConsumerState<_ChallengeSheet> {
  bool _saving = false;
  String? _error;

  Future<void> _complete() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await ref.read(completeChallengeUseCaseProvider)(
      widget.challenge.id,
    );
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        Navigator.of(context).pop(value);
      case Err(:final failure):
        setState(() {
          _saving = false;
          _error = failure.message;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.challenge;
    final text = Theme.of(context).textTheme;
    final (chipBg, chipFg, chipLabel) = switch (c.status) {
      ChallengeStatus.done => (
        AppColors.successTint,
        AppColors.successDark,
        'Cumplido',
      ),
      ChallengeStatus.current => (
        AppColors.blue100,
        AppColors.blue800,
        'En curso',
      ),
      ChallengeStatus.locked => (
        AppColors.neutralFill,
        AppColors.ink2,
        'Bloqueado',
      ),
    };

    Widget pill(String label, Color bg, Color fg) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: text.bodySmall?.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );

    Widget notice(IconData icon, String message, Color bg, Color fg) =>
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: fg),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: text.bodyMedium?.copyWith(
                    fontSize: 14,
                    height: 1.4,
                    color: fg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        28 + MediaQuery.of(context).viewInsets.bottom,
      ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              pill(chipLabel, chipBg, chipFg),
              pill('+${c.xp} XP', AppColors.accentTint, AppColors.accentOn),
            ],
          ),
          const SizedBox(height: 14),
          Semantics(
            header: true,
            child: Text(
              c.title,
              style: text.titleLarge?.copyWith(fontSize: 22, height: 1.25),
            ),
          ),
          if (c.stageName != null) ...[
            const SizedBox(height: 12),
            Text(
              'Etapa: ${c.stageName}',
              style: text.bodySmall?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.muted,
              ),
            ),
          ],
          if (c.description != null) ...[
            const SizedBox(height: 12),
            Text(
              c.description!,
              style: text.bodyMedium?.copyWith(
                fontSize: 15,
                height: 1.5,
                color: AppColors.ink2,
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (c.status == ChallengeStatus.current)
            SizedBox(
              height: 54,
              child: FilledButton.icon(
                onPressed: _saving ? null : _complete,
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check, size: 20),
                label: const Text('Marcar como cumplido'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: text.bodyLarge?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          if (c.status == ChallengeStatus.locked)
            notice(
              Icons.lock_outline,
              'Completa el reto anterior para desbloquearlo.',
              AppColors.background,
              AppColors.ink2,
            ),
          if (c.status == ChallengeStatus.done)
            notice(
              Icons.check,
              'Reto cumplido. La recompensa ya está en tu perfil.',
              AppColors.successTint,
              AppColors.successDark,
            ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            notice(
              Icons.error_outline,
              _error!,
              AppColors.accentTint,
              AppColors.accentOn,
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: _saving ? null : () => Navigator.of(context).pop(),
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
              child: const Text('Cerrar'),
            ),
          ),
        ],
      ),
    );
  }
}
