import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/app_colors.dart';
import '../controllers/auth_controller.dart';
import 'tour_controller.dart';
import 'tour_steps.dart';
import 'tour_targets.dart';

/// Tutorial guiado de primer ingreso: oscurece la pantalla, resalta un elemento
/// real y explica para qué sirve. Cambia de pestaña al avanzar de paso.
///
/// Se monta una sola vez encima de la barra inferior (`AppShell`), que le dice
/// en qué pestaña está ([currentTab]) y cómo cambiarla ([onSelectTab]).
class GuidedTour extends ConsumerStatefulWidget {
  const GuidedTour({
    super.key,
    required this.currentTab,
    required this.onSelectTab,
  });

  final int currentTab;
  final ValueChanged<int> onSelectTab;

  @override
  ConsumerState<GuidedTour> createState() => _GuidedTourState();
}

class _GuidedTourState extends ConsumerState<GuidedTour> {
  static const _autoStartDelay = Duration(milliseconds: 700);
  static const _pad = 6.0;

  Timer? _autoStart;
  Rect? _hole;

  /// Invalida mediciones viejas cuando el paso cambia mientras se espera.
  int _run = 0;

  @override
  void initState() {
    super.initState();
    _autoStart = Timer(_autoStartDelay, () {
      final user = ref.read(authControllerProvider).value?.user;
      if (!mounted || user == null) return;
      if (user.isEntrepreneur && !user.hasSeenTutorial) {
        ref.read(tourControllerProvider.notifier).start();
      }
    });
  }

  @override
  void dispose() {
    _autoStart?.cancel();
    super.dispose();
  }

  void _finish() {
    ref.read(tourControllerProvider.notifier).close();
    unawaited(
      ref.read(authControllerProvider.notifier).setTutorialCompleted(true),
    );
  }

  /// Va a la pestaña del paso, espera a que el elemento exista y lo mide.
  Future<void> _locate(TourStep step) async {
    final run = ++_run;
    if (step.tab != widget.currentTab) widget.onSelectTab(step.tab);
    final id = step.target;
    if (id == null) {
      setState(() => _hole = null);
      return;
    }
    final targets = ref.read(tourTargetsProvider);
    // La pestaña puede tardar en cargar sus datos: se reintenta ~2 s.
    for (var i = 0; i < 20; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (!mounted || run != _run) return;
      if (widget.currentTab != step.tab || targets.rectOf(id) == null) continue;
      await targets.reveal(id);
      if (!mounted || run != _run) return;
      final rect = targets.rectOf(id);
      if (rect != null) {
        setState(() => _hole = rect.inflate(_pad));
        return;
      }
    }
    if (mounted && run == _run) setState(() => _hole = null);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(tourControllerProvider, (prev, next) {
      if (!next.open) {
        _run++;
        setState(() => _hole = null);
        return;
      }
      if (prev?.open != true || prev?.step != next.step) {
        final steps = ref.read(tourStepsProvider);
        _locate(steps[next.step]);
      }
    });

    final tour = ref.watch(tourControllerProvider);
    if (!tour.open) return const SizedBox.shrink();
    final steps = ref.watch(tourStepsProvider);
    final step = steps[tour.step];
    final screen = MediaQuery.sizeOf(context);
    final animate = !MediaQuery.disableAnimationsOf(context);
    final hole = _hole == null
        ? Rect.fromCenter(
            center: screen.center(Offset.zero),
            width: 0,
            height: 0,
          )
        : _hole!.intersect(Offset.zero & screen);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _finish();
      },
      child: Stack(
        children: [
          // Bloquea toques sobre la app mientras dura el recorrido.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: TweenAnimationBuilder<Rect?>(
                tween: RectTween(end: hole),
                duration: animate
                    ? const Duration(milliseconds: 280)
                    : Duration.zero,
                curve: Curves.easeOutCubic,
                builder: (_, rect, _) =>
                    CustomPaint(painter: _SpotlightPainter(rect ?? hole)),
              ),
            ),
          ),
          Positioned.fill(
            child: CustomSingleChildLayout(
              delegate: _BalloonLayout(_hole, MediaQuery.paddingOf(context)),
              child: _Balloon(
                step: step,
                index: tour.step,
                total: steps.length,
                onSkip: _finish,
                onPrev: ref.read(tourControllerProvider.notifier).prev,
                onNext: tour.step == steps.length - 1
                    ? _finish
                    : ref.read(tourControllerProvider.notifier).next,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  const _SpotlightPainter(this.hole);

  final Rect hole;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(hole, const Radius.circular(14));
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(rrect);
    canvas.drawPath(
      path,
      Paint()..color = AppColors.navy950.withValues(alpha: 0.78),
    );
    if (hole.width > 0 && hole.height > 0) {
      canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = AppColors.blueRing,
      );
    }
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) => old.hole != hole;
}

/// Coloca el globo debajo del elemento resaltado, o encima si no cabe;
/// centrado si el paso no resalta nada.
class _BalloonLayout extends SingleChildLayoutDelegate {
  const _BalloonLayout(this.target, this.safe);

  final Rect? target;
  final EdgeInsets safe;

  static const _margin = 16.0;
  static const _gap = 14.0;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints(
        maxWidth: math.min(constraints.maxWidth - _margin * 2, 380),
        maxHeight: constraints.maxHeight - safe.vertical - _margin * 2,
      );

  @override
  Offset getPositionForChild(Size size, Size child) {
    final x = (size.width - child.width) / 2;
    final top = safe.top + _margin;
    final bottom = size.height - safe.bottom - _margin;
    final t = target;
    if (t == null) return Offset(x, (size.height - child.height) / 2);
    final below = t.bottom + _gap;
    if (below + child.height <= bottom) return Offset(x, below);
    final above = t.top - _gap - child.height;
    if (above >= top) return Offset(x, above);
    return Offset(x, math.max(top, bottom - child.height));
  }

  @override
  bool shouldRelayout(_BalloonLayout old) =>
      old.target != target || old.safe != safe;
}

class _Balloon extends StatelessWidget {
  const _Balloon({
    required this.step,
    required this.index,
    required this.total,
    required this.onSkip,
    required this.onPrev,
    required this.onNext,
  });

  final TourStep step;
  final int index;
  final int total;
  final VoidCallback onSkip;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final first = index == 0;
    final last = index == total - 1;
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      label: 'Tutorial, paso ${index + 1} de $total',
      child: Material(
        color: AppColors.surface,
        elevation: 8,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '${index + 1} de $total',
                    style: text.bodySmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  if (!last)
                    TextButton(
                      onPressed: onSkip,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: const Text('Saltar'),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Semantics(
                header: true,
                liveRegion: true,
                child: Text(step.title, style: text.titleMedium),
              ),
              const SizedBox(height: 6),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    step.body,
                    style: text.bodyMedium?.copyWith(color: AppColors.ink2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (!first)
                    TextButton(
                      onPressed: onPrev,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      child: const Text('Anterior'),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: onNext,
                    child: Text(last ? 'Empezar' : 'Siguiente'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
