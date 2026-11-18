import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../shared/widgets/motion.dart';
import '../../domain/entities/mentor.dart';
import '../../domain/entities/time_slot.dart';
import '../controllers/booking_providers.dart';
import '../../../../shared/widgets/state_views.dart';

/// Agendar una mentoría: asesor asignado → día → turno libre → confirmar.
/// Al confirmar se vuelve a verificar el horario (puede haberse ocupado).
class BookSessionScreen extends ConsumerStatefulWidget {
  const BookSessionScreen({super.key});

  @override
  ConsumerState<BookSessionScreen> createState() => _BookSessionScreenState();
}

class _BookSessionScreenState extends ConsumerState<BookSessionScreen> {
  static const _daysAhead = 14;

  final _topic = TextEditingController();
  Mentor? _mentor;
  late DateTime _day = _today();
  TimeSlot? _slot;
  bool _submitting = false;
  bool _booked = false;
  String? _error;

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _topic.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final mentor = _mentor;
    final slot = _slot;
    if (_submitting || mentor == null || slot == null) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final failure = await ref
        .read(bookingControllerProvider.notifier)
        .book(mentor: mentor, day: _day, slot: slot, topic: _topic.text);
    if (!mounted) return;
    if (failure == null) {
      HapticFeedback.mediumImpact();
      setState(() {
        _submitting = false;
        _booked = true;
      });
      return;
    }
    setState(() {
      _submitting = false;
      _error = failure.message;
      // El horario ya no está libre: que elija otro de la lista renovada.
      if (failure is SlotUnavailableFailure) _slot = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final mentors = ref.watch(mentorsProvider);

    if (_booked) {
      return _BookedView(
        mentor: _mentor!.name,
        when: '${longDate(_day)} a las ${_slot!.label}',
        onDone: () => context.pop(),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Agendar mentoría')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Text('1. Elige a tu asesor', style: text.titleMedium),
            const SizedBox(height: 10),
            mentors.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => _Retry(
                message: error is Failure
                    ? error.message
                    : 'No se pudo cargar a tus asesores.',
                onRetry: () => ref.invalidate(mentorsProvider),
              ),
              data: (list) => list.isEmpty
                  ? Text(
                      'Todavía no tienes un asesor asignado. El CIE-U te asignará '
                      'uno cuando tu emprendimiento esté listo.',
                      style: text.bodyMedium?.copyWith(color: AppColors.muted),
                    )
                  : Column(
                      children: [
                        for (final m in list)
                          _MentorTile(
                            mentor: m,
                            selected: _mentor?.id == m.id,
                            onTap: m.locked
                                ? null
                                : () => setState(() {
                                    _mentor = m;
                                    _slot = null;
                                    _error = null;
                                  }),
                          ),
                      ],
                    ),
            ),
            if (_mentor != null) ...[
              const SizedBox(height: 22),
              Text('2. Elige el día', style: text.titleMedium),
              const SizedBox(height: 10),
              SizedBox(
                height: 76,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _daysAhead,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final day = _today().add(Duration(days: i));
                    final selected = day == _day;
                    return ChoiceChip(
                      selected: selected,
                      onSelected: (_) => setState(() {
                        _day = day;
                        _slot = null;
                        _error = null;
                      }),
                      label: SizedBox(
                        width: 44,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(weekdayShort(day)),
                            Text(
                              '${day.day}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 22),
              Text('3. Elige el horario', style: text.titleMedium),
              const SizedBox(height: 10),
              _Slots(
                query: (mentorId: _mentor!.id, day: _day),
                selected: _slot,
                onSelected: (s) => setState(() {
                  _slot = s;
                  _error = null;
                }),
              ),
              const SizedBox(height: 22),
              Text(
                '4. ¿De qué quieres hablar? (opcional)',
                style: text.titleMedium,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _topic,
                maxLength: 250,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'Tema',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Semantics(
                liveRegion: true,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accentTint,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    _error!,
                    style: text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentOn,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: (_slot == null || _submitting) ? null : _confirm,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Confirmar mentoría'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MentorTile extends StatelessWidget {
  const _MentorTile({
    required this.mentor,
    required this.selected,
    required this.onTap,
  });

  final Mentor mentor;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        button: true,
        selected: selected,
        enabled: onTap != null,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Opacity(
            opacity: mentor.locked ? 0.6 : 1,
            child: Container(
              constraints: const BoxConstraints(minHeight: 64),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: selected ? AppColors.blue50 : AppColors.surface,
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border,
                  width: selected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: selected ? AppColors.primary : AppColors.muted,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mentor.name,
                          style: text.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if ((mentor.specialty ?? '').isNotEmpty)
                          Text(
                            mentor.specialty!,
                            style: text.bodySmall?.copyWith(
                              color: AppColors.muted,
                            ),
                          ),
                        if (mentor.locked &&
                            (mentor.lockReason ?? '').isNotEmpty)
                          Text(
                            mentor.lockReason!,
                            style: text.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.warningOn,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Slots extends ConsumerWidget {
  const _Slots({
    required this.query,
    required this.selected,
    required this.onSelected,
  });

  final SlotsQuery query;
  final TimeSlot? selected;
  final ValueChanged<TimeSlot> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    return ref
        .watch(slotsProvider(query))
        .when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => _Retry(
            message: error is Failure
                ? error.message
                : 'No se pudieron cargar los horarios.',
            onRetry: () => ref.invalidate(slotsProvider),
          ),
          data: (slots) => slots.isEmpty
              ? Text(
                  'Tu asesor no tiene horarios ese día. Prueba con otra fecha.',
                  style: text.bodyMedium?.copyWith(color: AppColors.muted),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in slots)
                      ChoiceChip(
                        label: Text(s.label),
                        selected: selected?.start == s.start,
                        onSelected: s.available ? (_) => onSelected(s) : null,
                      ),
                  ],
                ),
        );
  }
}

class _Retry extends StatelessWidget {
  const _Retry({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ErrorState(
    message: message,
    onRetry: onRetry,
    padding: const EdgeInsets.symmetric(vertical: 8),
  );
}

/// Confirmación a pantalla completa: la mentoría quedó agendada y con quién.
class _BookedView extends StatelessWidget {
  const _BookedView({
    required this.mentor,
    required this.when,
    required this.onDone,
  });

  final String mentor;
  final String when;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            children: [
              const Spacer(),
              RippleBurst(
                color: AppColors.success,
                child: PopIn(
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.success,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 52,
                      color: AppColors.onNavy,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
              FadeUp(
                delay: const Duration(milliseconds: 200),
                child: Semantics(
                  header: true,
                  liveRegion: true,
                  child: Text(
                    'Mentoría agendada',
                    textAlign: TextAlign.center,
                    style: text.headlineMedium,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FadeUp(
                delay: const Duration(milliseconds: 300),
                child: Text(
                  'Con $mentor, el $when. La verás en tu lista de mentorías.',
                  textAlign: TextAlign.center,
                  style: text.bodyLarge?.copyWith(
                    height: 1.5,
                    color: AppColors.muted,
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: onDone,
                  child: const Text('Ver mis mentorías'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
