import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import 'orbit_backdrop.dart';
import 'pulsing_logo.dart';

/// Estructura común de login y registro: fondo navy con órbitas, logo,
/// título, formulario y un pie anclado abajo.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.form,
    required this.footer,
    this.leading,
  });

  final String title;
  final String subtitle;
  final Widget form;
  final Widget footer;

  /// Control opcional sobre el logo (p. ej. «volver»).
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.navy950,
      body: Stack(
        children: [
          const Positioned(left: -10, top: -120, child: OrbitBackdrop()),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 24, 28, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ?leading,
                        const SizedBox(height: 24),
                        const PulsingLogo(),
                        const SizedBox(height: 20),
                        Semantics(
                          header: true,
                          child: Text(
                            title,
                            style: text.headlineLarge?.copyWith(
                              color: AppColors.onNavy,
                              height: 1.12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          subtitle,
                          style: text.bodyLarge?.copyWith(
                            fontSize: 16,
                            height: 1.5,
                            color: AppColors.onNavyMuted,
                          ),
                        ),
                        const SizedBox(height: 32),
                        form,
                        const Spacer(),
                        Center(child: footer),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
