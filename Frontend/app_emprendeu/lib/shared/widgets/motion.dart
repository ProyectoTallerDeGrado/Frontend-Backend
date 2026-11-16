import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_tokens.dart';

/// Entrada de una pieza: aparece subiendo unos píxeles. Se usa en lo que **llega** a la pantalla
/// (un banner, un resultado), no en cada tarjeta de una lista. Con «reducir movimiento» se ve
/// en su estado final desde el primer cuadro.
class FadeUp extends StatelessWidget {
  const FadeUp({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppMotion.panel,
    this.offset = 14,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offset;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return child;
    final total = delay + duration;
    final start = delay.inMicroseconds / total.inMicroseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(start, 1, curve: AppMotion.enter),
      child: child,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * offset),
          child: child,
        ),
      ),
    );
  }
}

/// Aparición con rebote: confirma una acción o celebra un logro (una medalla, un check).
class PopIn extends StatelessWidget {
  const PopIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppMotion.emphasis,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return child;
    final total = delay + duration;
    final start = delay.inMicroseconds / total.inMicroseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(start, 1),
      child: child,
      builder: (context, t, child) => Opacity(
        opacity: (t * 3).clamp(0, 1),
        child: Transform.scale(
          scale: 0.6 + 0.4 * AppMotion.spring.transform(t),
          child: child,
        ),
      ),
    );
  }
}

/// Anillo que se expande una vez desde detrás de [child]: el motivo *ripple* del logo, usado
/// como énfasis puntual. No se repite.
class RippleBurst extends StatelessWidget {
  const RippleBurst({
    super.key,
    required this.child,
    required this.color,
    this.size = 96,
  });

  final Widget child;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.celebrate,
      curve: AppMotion.enter,
      child: child,
      builder: (context, t, child) => Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          for (final lag in const [0.0, 0.25])
            if (t > lag)
              IgnorePointer(
                child: Builder(
                  builder: (context) {
                    final p = ((t - lag) / (1 - lag)).clamp(0.0, 1.0);
                    return Container(
                      width: size * (1 + p * 1.1),
                      height: size * (1 + p * 1.1),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: color.withValues(alpha: (1 - p) * 0.55),
                          width: 2,
                        ),
                      ),
                    );
                  },
                ),
              ),
          child!,
        ],
      ),
    );
  }
}

/// Tres puntos que laten: alguien (el coach) está escribiendo.
class TypingDots extends StatefulWidget {
  const TypingDots({super.key, required this.semanticsLabel});

  final String semanticsLabel;

  @override
  State<TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
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
    return Semantics(
      label: widget.semanticsLabel,
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
            bottomLeft: Radius.circular(6),
          ),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++)
                Padding(
                  padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
                  child: _dot((_controller.value - i * 0.18) % 1.0),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dot(double phase) {
    // Sube y vuelve en el primer 40 % del ciclo; el resto descansa.
    final lift = phase < 0.4
        ? Curves.easeInOut.transform(1 - (phase / 0.2 - 1).abs())
        : 0.0;
    return Transform.translate(
      offset: Offset(0, -4 * lift),
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Color.lerp(AppColors.borderStrong, AppColors.primary, lift),
        ),
      ),
    );
  }
}

/// Pieza de carga con la forma de lo que viene, para que la pantalla no salte al llegar el dato.
class Skeleton extends StatefulWidget {
  const Skeleton({
    super.key,
    this.width,
    required this.height,
    this.radius = AppRadii.control,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
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
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(
              AppColors.neutralFill,
              AppColors.divider,
              Curves.easeInOut.transform(_controller.value),
            ),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        ),
      ),
    );
  }
}
