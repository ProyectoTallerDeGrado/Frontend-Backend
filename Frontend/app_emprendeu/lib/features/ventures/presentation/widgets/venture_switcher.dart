import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../controllers/ventures_providers.dart';

/// Selector del emprendimiento activo. Solo aparece si el usuario está en varios:
/// al cambiarlo, Inicio, Camino, Mentorías y Coach pasan a ese emprendimiento.
class VentureSwitcher extends ConsumerWidget {
  const VentureSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ventures = ref.watch(myVenturesProvider).value ?? const [];
    final current = ref.watch(myVentureProvider).value;
    if (ventures.length < 2 || current == null) return const SizedBox.shrink();
    return DropdownButtonFormField<int>(
      key: ValueKey('venture-switcher-${current.id}'),
      initialValue: current.id,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Emprendimiento',
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      items: [
        for (final v in ventures)
          DropdownMenuItem(
            value: v.id,
            child: Text(v.name, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (id) {
        if (id != null) ref.read(selectedVentureIdProvider.notifier).select(id);
      },
    );
  }
}
