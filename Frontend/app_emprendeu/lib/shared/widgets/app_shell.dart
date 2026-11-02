import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/mentoring/index.dart';
import 'app_bottom_nav.dart';

const _items = [
  BottomNavItem(label: 'Inicio', icon: Icons.home_outlined),
  BottomNavItem(label: 'Camino', icon: Icons.flag_outlined),
  BottomNavItem(label: 'Mentorías', icon: Icons.event_outlined),
  BottomNavItem(label: 'Coach', icon: Icons.smart_toy_outlined),
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
      body: navigationShell,
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
