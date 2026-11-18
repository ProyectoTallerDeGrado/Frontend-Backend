import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_colors.dart';

class BottomNavItem {
  const BottomNavItem({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

/// Barra inferior del diseño: icono dentro de una píldora `blue50` cuando está activo.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onSelected,
  });

  final List<BottomNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: i == currentIndex,
                    label: items[i].label,
                    child: InkWell(
                      onTap: () {
                        if (i != currentIndex) HapticFeedback.selectionClick();
                        onSelected(i);
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 56,
                            height: 30,
                            decoration: BoxDecoration(
                              color: i == currentIndex
                                  ? AppColors.blue50
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Icon(
                              items[i].icon,
                              size: 22,
                              color: i == currentIndex
                                  ? AppColors.primary
                                  : AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            items[i].label,
                            style: text.bodySmall?.copyWith(
                              fontSize: 12,
                              fontWeight: i == currentIndex
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: i == currentIndex
                                  ? AppColors.primary
                                  : AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
