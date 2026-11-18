import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../../../app/theme/app_colors.dart';

/// Órbitas decorativas del fondo de acceso (motivo de marca).
/// Gira lentamente salvo que el sistema pida reducir el movimiento.
class OrbitBackdrop extends StatefulWidget {
  const OrbitBackdrop({super.key});

  @override
  State<OrbitBackdrop> createState() => _OrbitBackdropState();
}

class _OrbitBackdropState extends State<OrbitBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 110),
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
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              size: const Size(420, 420),
              painter: _OrbitPainter(_controller.value),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrbitPainter extends CustomPainter {
  _OrbitPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final scale = size.width / 400;

    // Órbita interna punteada: 70 s por vuelta.
    final inner = 150 * scale;
    _dashedCircle(
      canvas,
      c,
      inner,
      Paint()
        ..color = AppColors.onNavy.withValues(alpha: 0.14)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    final a1 = 2 * math.pi * t * (110 / 70);
    canvas.drawCircle(
      c + Offset(math.cos(a1), math.sin(a1)) * inner,
      7 * scale,
      Paint()..color = AppColors.accentBright,
    );

    // Órbita externa continua: sentido inverso.
    final outer = 195 * scale;
    canvas.drawCircle(
      c,
      outer,
      Paint()
        ..color = AppColors.primary.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    final a2 = -2 * math.pi * t - math.pi / 2;
    canvas.drawCircle(
      c + Offset(math.cos(a2), math.sin(a2)) * outer,
      6 * scale,
      Paint()..color = AppColors.onNavy,
    );
  }

  void _dashedCircle(Canvas canvas, Offset c, double r, Paint paint) {
    const dash = 4.0, gap = 10.0;
    final step = (dash + gap) / r;
    for (var a = 0.0; a < 2 * math.pi; a += step) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        a,
        dash / r,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_OrbitPainter old) => old.t != t;
}
