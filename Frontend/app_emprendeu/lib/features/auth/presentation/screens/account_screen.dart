import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../ai_assistant/index.dart';
import '../../../documents/index.dart';
import '../../../gamification/index.dart';
import '../../../needs/index.dart';
import '../../../training/index.dart';
import '../../../ventures/index.dart';
import '../auth_routes.dart';
import '../controllers/auth_controller.dart';

/// Pestaña «Perfil»: cuenta, emprendimiento, XP e insignias, y cierre de sesión.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value?.user;
    final text = Theme.of(context).textTheme;
    if (user == null) return const SizedBox.shrink();

    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: text.bodyMedium?.copyWith(
                fontSize: 14,
                color: AppColors.muted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: text.bodyMedium?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    final outlined = OutlinedButton.styleFrom(
      foregroundColor: AppColors.ink,
      side: const BorderSide(color: AppColors.borderStrong, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: text.bodyMedium?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Sesión iniciada',
                style: text.bodyMedium?.copyWith(color: AppColors.muted),
              ),
              const SizedBox(height: 4),
              Text('Hola, ${user.nombre}', style: text.headlineMedium),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    row('Nombre', user.fullName),
                    row('Correo', user.email),
                    row('Rol', 'Emprendedor'),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const MyVentureCard(),
              const SizedBox(height: 14),
              const XpBadgesSection(),
              const SizedBox(height: 14),
              const LocalAiSection(),
              const SizedBox(height: 14),
              if (ref.watch(myVentureProvider).value != null) ...[
                SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () => context.push(NeedsRoutes.list),
                    icon: const Icon(Icons.support_agent_outlined, size: 18),
                    label: const Text('Necesidades y dificultades'),
                    style: outlined,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () => context.push(DocumentsRoutes.list),
                    icon: const Icon(Icons.folder_open_outlined, size: 18),
                    label: const Text('Documentos'),
                    style: outlined,
                  ),
                ),
                const SizedBox(height: 14),
              ],
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () => context.push(TrainingRoutes.list),
                  icon: const Icon(Icons.school_outlined, size: 18),
                  label: const Text('Capacitaciones'),
                  style: outlined,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () => context.push(AuthRoutes.changePassword),
                  icon: const Icon(Icons.lock_outline, size: 18),
                  label: const Text('Cambiar contraseña'),
                  style: outlined,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      ref.read(authControllerProvider.notifier).logout(),
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Cerrar sesión'),
                  style: outlined,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
