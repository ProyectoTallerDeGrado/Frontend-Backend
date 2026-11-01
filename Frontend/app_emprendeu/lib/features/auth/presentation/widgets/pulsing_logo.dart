import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

/// Logo del CIE-U con dos anillos que se expanden (`design.md` §5).
class PulsingLogo extends StatefulWidget {
  const PulsingLogo({super.key, this.size = 84});

  final double size;

  @override
  State<PulsingLogo> createState() => _PulsingLogoState();
}

class _PulsingLogoState extends State<PulsingLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
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

  Widget _ring(double phase, Color color) {
    final v = (_controller.value + phase) % 1.0;
    return Transform.scale(
      scale: 0.7 + 1.4 * v,
      child: Opacity(
        opacity: (0.7 * (1 - v)).clamp(0.0, 1.0),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.size * 0.26),
            border: Border.all(color: color, width: 2),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Logo del CIE-U',
      image: true,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ExcludeSemantics(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => Stack(
                  children: [
                    _ring(0, AppColors.accentBright),
                    _ring(0.5, AppColors.onNavy),
                  ],
                ),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(widget.size * 0.26),
              child: Image.asset(
                'assets/images/cie_u_logo.png',
                width: widget.size,
                height: widget.size,
                fit: BoxFit.cover,
                excludeFromSemantics: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
