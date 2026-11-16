import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_tokens.dart';
import '../../features/mentoring/index.dart';
import 'app_bottom_nav.dart';

const _items = [
  BottomNavItem(label: 'Inicio', icon: Icons.home_outlined),
  BottomNavItem(label: 'Camino', icon: Icons.flag_outlined),
  BottomNavItem(label: 'Mentorías', icon: Icons.event_outlined),
  BottomNavItem(label: 'Coach', icon: Icons.auto_awesome_outlined),
  BottomNavItem(label: 'Perfil', icon: Icons.person_outline),
];

/// Estructura de las pantallas con sesión: contenido + barra inferior.
/// Mantiene viva la sincronización de lo guardado sin conexión.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(syncControllerProvider);
    return Scaffold(
      body: _TabFade(
        index: navigationShell.currentIndex,
        child: navigationShell,
      ),
      bottomNavigationBar: AppBottomNav(
        items: _items,
        currentIndex: navigationShell.currentIndex,
        onSelected: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

/// Fundido corto al cambiar de pestaña. No remonta las ramas: cada una conserva su estado.
class _TabFade extends StatefulWidget {
  const _TabFade({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_TabFade> createState() => _TabFadeState();
}

class _TabFadeState extends State<_TabFade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.control,
    value: 1,
  );
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: AppMotion.enter,
  );

  @override
  void didUpdateWidget(_TabFade old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index &&
        !MediaQuery.of(context).disableAnimations) {
      _controller.forward(from: 0.35);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: _opacity, child: widget.child);
}
