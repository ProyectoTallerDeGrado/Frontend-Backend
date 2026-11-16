import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../ai_assistant/index.dart';
import '../../../documents/index.dart';
import '../../../gamification/index.dart';
import '../../../needs/index.dart';
import '../../../training/index.dart';
import '../../../ventures/index.dart';
import '../auth_routes.dart';
import '../controllers/auth_controller.dart';

/// Pestaña «Perfil»: identidad, emprendimiento, XP e insignias, accesos y cierre de sesión.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value?.user;
    final text = Theme.of(context).textTheme;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screen,
            AppSpacing.xxl,
            AppSpacing.screen,
            AppSpacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text('Perfil', style: text.headlineMedium),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  ExcludeSemantics(
                    child: Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.navy900,
                      ),
                      child: Text(
                        _initials(user.fullName),
                        style: text.titleMedium?.copyWith(
                          color: AppColors.onNavy,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.fullName, style: text.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          user.email,
                          style: text.bodyMedium?.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              const MyVentureCard(),
              const SizedBox(height: 14),
              const XpBadgesSection(),
              const SizedBox(height: 14),
              const LocalAiSection(),
              const SizedBox(height: 14),
              _MenuGroup(
                rows: [
                  if (ref.watch(myVentureProvider).value != null) ...[
                    _MenuRow(
                      icon: Icons.support_agent_outlined,
                      label: 'Necesidades y dificultades',
                      onTap: () => context.push(NeedsRoutes.list),
                    ),
                    _MenuRow(
                      icon: Icons.folder_open_outlined,
                      label: 'Documentos',
                      onTap: () => context.push(DocumentsRoutes.list),
                    ),
                  ],
                  _MenuRow(
                    icon: Icons.school_outlined,
                    label: 'Capacitaciones',
                    onTap: () => context.push(TrainingRoutes.list),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _MenuGroup(
                rows: [
                  _MenuRow(
                    icon: Icons.lock_outline,
                    label: 'Cambiar contraseña',
                    onTap: () => context.push(AuthRoutes.changePassword),
                  ),
                  _MenuRow(
                    icon: Icons.logout,
                    label: 'Cerrar sesión',
                    leaves: true,
                    onTap: () =>
                        ref.read(authControllerProvider.notifier).logout(),
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

String _initials(String fullName) {
  final parts = fullName
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  final letters = parts.length == 1
      ? parts.first.substring(0, 1)
      : parts.first.substring(0, 1) + parts.last.substring(0, 1);
  return letters.toUpperCase();
}

/// Grupo de accesos del Perfil: una tarjeta con filas separadas por una línea.
class _MenuGroup extends StatelessWidget {
  const _MenuGroup({required this.rows});

  final List<_MenuRow> rows;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(indent: 52),
            rows[i],
          ],
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.leaves = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// La acción saca de la app (cerrar sesión): no lleva flecha de «ir a».
  final bool leaves;

  @override
  Widget build(BuildContext context) {
    final color = leaves ? AppColors.error : AppColors.ink;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 22, color: leaves ? color : AppColors.muted),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
                if (!leaves)
                  const Icon(
                    Icons.chevron_right,
                    size: 22,
                    color: AppColors.borderStrong,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
