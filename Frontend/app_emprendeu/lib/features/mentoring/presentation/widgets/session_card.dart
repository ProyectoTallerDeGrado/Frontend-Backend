import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/date_format.dart';
import '../../domain/entities/mentoring_session.dart';

/// Una mentoría en la lista: cuándo, con quién, de qué y en qué estado está.
class SessionCard extends StatelessWidget {
  const SessionCard({super.key, required this.session});

  final MentoringSession session;

  (String, Color, Color) get _badge => switch (session.state) {
    SessionState.scheduled => (
      'Programada',
      AppColors.blue50,
      AppColors.primary,
    ),
    SessionState.done => (
      'Realizada',
      AppColors.successTint,
      AppColors.successDark,
    ),
    SessionState.cancelled => (
      'Cancelada',
      AppColors.accentTint,
      AppColors.accentOn,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final when = session.when;
    final (label, background, foreground) = _badge;
    final extras = [
      if (session.recommendations > 0)
        '${session.recommendations} ${session.recommendations == 1 ? 'recomendación' : 'recomendaciones'}',
      if (session.commitments > 0)
        '${session.commitments} compromiso${session.commitments == 1 ? '' : 's'}',
    ];
    return Semantics(
      container: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    when == null ? 'Sin fecha' : sessionWhen(when),
                    style: text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    label,
                    style: text.bodySmall?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: foreground,
                    ),
                  ),
                ),
              ],
            ),
            if ((session.topic ?? '').isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(session.topic!, style: text.bodyMedium),
            ],
            const SizedBox(height: 6),
            Text(
              [
                if (session.mentorName != null) 'Con ${session.mentorName}',
                if ((session.specialty ?? '').isNotEmpty) session.specialty!,
              ].join(' · '),
              style: text.bodySmall?.copyWith(
                fontSize: 13,
                color: AppColors.muted,
              ),
            ),
            if (extras.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                extras.join(' · '),
                style: text.bodySmall?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
