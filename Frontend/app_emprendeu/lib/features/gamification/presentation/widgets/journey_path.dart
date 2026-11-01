import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/journey.dart';

const double _nodeSize = 64;
const double _rowHeight = 110;
const double _top = 60;

/// Posición del centro de cada nodo: zigzag izquierda/derecha.
List<Offset> nodeCenters(int count, double width) => [
  for (var i = 0; i < count; i++)
    Offset(i.isEven ? width * 0.26 : width * 0.67, _top + i * _rowHeight),
];

/// Alto del lienzo para [count] retos.
double pathHeight(int count) => _top + (count - 1) * _rowHeight + 90;

/// Camino gamificado: curva punteada con tramo verde hasta el último reto cumplido
/// y un nodo tocable por reto.
class JourneyPath extends StatelessWidget {
  const JourneyPath({
    super.key,
    required this.challenges,
    required this.onOpen,
  });

  final List<JourneyChallenge> challenges;
  final ValueChanged<JourneyChallenge> onOpen;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final centers = nodeCenters(challenges.length, width);
        final done = challenges
            .where((c) => c.status == ChallengeStatus.done)
            .length;
        final target = math.max(0, done - 1).toDouble();
        return SizedBox(
          width: width,
          height: pathHeight(challenges.length),
          child: Stack(
            children: [
              Positioned.fill(
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(end: target),
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 1300),
                  curve: Curves.easeOutCubic,
                  builder: (context, progress, _) =>
                      CustomPaint(painter: _PathPainter(centers, progress)),
                ),
              ),
              for (var i = 0; i < challenges.length; i++) ...[
                Positioned(
                  left: centers[i].dx - _nodeSize / 2,
                  top: centers[i].dy - _nodeSize / 2,
                  child: _Node(
                    challenge: challenges[i],
                    position: i + 1,
                    onTap: () => onOpen(challenges[i]),
                  ),
                ),
                _Label(
                  challenge: challenges[i],
                  center: centers[i],
                  width: width,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _PathPainter extends CustomPainter {
  _PathPainter(this.centers, this.progress);

  final List<Offset> centers;

  /// En «unidades de nodo»: 0 = ninguno, 1 = hasta el segundo nodo, etc.
  final double progress;

  Path _upTo(int index) {
    final path = Path()..moveTo(centers[0].dx, centers[0].dy);
    for (var i = 0; i < index; i++) {
      final a = centers[i], b = centers[i + 1];
      path.cubicTo(a.dx, a.dy + 55, b.dx, b.dy - 55, b.dx, b.dy);
    }
    return path;
  }

  double _length(int index) {
    if (index <= 0) return 0;
    final metrics = _upTo(index).computeMetrics().toList();
    return metrics.isEmpty ? 0 : metrics.first.length;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (centers.length < 2) return;
    final full = _upTo(centers.length - 1);

    // Tramo pendiente: puntos azules.
    final dot = Paint()..color = AppColors.blueTrack;
    final metric = full.computeMetrics().first;
    for (double d = 0; d < metric.length; d += 15) {
      final tangent = metric.getTangentForOffset(d);
      if (tangent != null) canvas.drawCircle(tangent.position, 3.6, dot);
    }

    // Tramo cumplido: línea verde continua.
    final lower = progress.floor().clamp(0, centers.length - 1);
    final upper = progress.ceil().clamp(0, centers.length - 1);
    final fraction = progress - progress.floor();
    final length = ui.lerpDouble(_length(lower), _length(upper), fraction) ?? 0;
    if (length > 0) {
      canvas.drawPath(
        metric.extractPath(0, length),
        Paint()
          ..color = AppColors.success
          ..style = PaintingStyle.stroke
          ..strokeWidth = 9
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_PathPainter old) =>
      old.progress != progress || old.centers != centers;
}

class _Node extends StatelessWidget {
  const _Node({
    required this.challenge,
    required this.position,
    required this.onTap,
  });

  final JourneyChallenge challenge;
  final int position;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (bg, icon, fg, border, label) = switch (challenge.status) {
      ChallengeStatus.done => (
        AppColors.success,
        Icons.check,
        Colors.white,
        null,
        'cumplido',
      ),
      ChallengeStatus.current => (
        AppColors.primary,
        Icons.flag,
        Colors.white,
        null,
        'en curso',
      ),
      ChallengeStatus.locked => (
        AppColors.neutralFill,
        Icons.lock_outline,
        AppColors.muted,
        const BorderSide(color: AppColors.borderStrong, width: 2),
        'bloqueado',
      ),
    };
    return Semantics(
      button: true,
      label: 'Reto $position: ${challenge.title}, $label',
      child: SizedBox(
        width: _nodeSize,
        height: _nodeSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (challenge.status == ChallengeStatus.current) const _Ripple(),
            Material(
              color: bg,
              shape: CircleBorder(side: border ?? BorderSide.none),
              elevation: challenge.status == ChallengeStatus.locked ? 0 : 4,
              shadowColor: bg.withValues(alpha: 0.6),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onTap,
                child: SizedBox(
                  width: _nodeSize,
                  height: _nodeSize,
                  child: Icon(icon, size: 28, color: fg),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Anillo que se expande detrás del reto en curso.
class _Ripple extends StatefulWidget {
  const _Ripple();

  @override
  State<_Ripple> createState() => _RippleState();
}

class _RippleState extends State<_Ripple> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => Transform.scale(
            scale: 1 + 0.9 * _controller.value,
            child: Opacity(
              opacity: 0.6 * (1 - _controller.value),
              child: Container(
                width: _nodeSize,
                height: _nodeSize,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({
    required this.challenge,
    required this.center,
    required this.width,
  });

  final JourneyChallenge challenge;
  final Offset center;
  final double width;

  @override
  Widget build(BuildContext context) {
    final right = center.dx > width / 2;
    final (status, color) = switch (challenge.status) {
      ChallengeStatus.done => (
        'Cumplido · +${challenge.xp} XP',
        AppColors.successDark,
      ),
      ChallengeStatus.current => (
        'En curso · +${challenge.xp} XP',
        AppColors.blue800,
      ),
      ChallengeStatus.locked => ('Bloqueado', AppColors.muted),
    };
    final text = Theme.of(context).textTheme;
    final child = SizedBox(
      width: 128,
      child: Column(
        crossAxisAlignment: right
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Text(
            challenge.title,
            textAlign: right ? TextAlign.right : TextAlign.left,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: text.titleMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            status,
            style: text.bodySmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
    return Positioned(
      top: center.dy - 20,
      left: right ? null : center.dx + 44,
      right: right ? width - (center.dx - 44) : null,
      child: ExcludeSemantics(child: child),
    );
  }
}
